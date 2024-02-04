import os
from pprint import pformat
from solidity_parser import parser
from nltk.translate.bleu_score import sentence_bleu, corpus_bleu
from pprint import pprint
import logging
import re
import json
import docker

# Logging

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s")

class SmartCMetrics:
    """This class is responsible for evaluating the quality of the smart contract evaluating the following metrics:
    - compilability [OK]
    - security [OK]
    - number of functions [OK]
    - number of functions whose logic is fully defined
    - presence of comments [OK]
    - presence of external calls
    - availability of value for parameters
    - BLEU score (if a reference is available)
    - CodeBLEU score (if a reference is available)
    """

    VUL_TOOLS = {
        "slither": {
            "docker_name": "slither",
            "docker_image": "trailofbits/eth-security-toolbox",
            "host_path": os.path.join(os.path.expanduser('~'), 'slither_shared' ),
            "container_path": "/share",
            "cmd": lambda sol_file, pragma: [f"solc-select install {pragma}", f"solc-select use {pragma}", f"slither {sol_file} --json -"],
            "cmd_err" : lambda sol_file, pragma: [f"solc-select use {pragma}", f"slither {sol_file}"] # This is the command to run if the last cmd returns a void json. Most likely, the smart contract does not compile
        },
        # Other vulnerability detection tools can be added
    }

    def __init__(self, path2sol: str, vul_tool: str = 'slither', path2sol_ref: str = None):
        assert os.path.exists(path2sol), f"Path to smart contract {path2sol} does not exist"
        self.vul_tool_name = vul_tool
        self.vul_tool = self.VUL_TOOLS[self.vul_tool_name]

        self.__path2sol = path2sol
        with open(self.__path2sol, 'r') as f:
            self.__sol_code_raw = f.read()

        self.__sol_code = self.remove_comments(self.__sol_code_raw)
        # Get file name and positin
        # Assuming the following stucture generated by the pipeline.
        # \---<legal agreement name>
        #     +---raw
        #     |       <legal agreement name>_t<tempersture value>_raw.txt
        #     |       
        #     +---sc
        #     |       <legal agreement name>_t<tempersture value>.sol
        #     |       
        #     \---vul
        #             <legal agreement name>_t<tempersture value>.sol.json

        self.__file_name = os.path.basename(path2sol) # <legal agreement name>_t<tempersture value>.sol
        self.__vul_folder = os.path.dirname(path2sol).replace('sc', 'vul') # abs path to 'vul' folder
        self.__vul_report_file_path = os.path.join(self.__vul_folder, self.__file_name + '.json') # abs path to vulnerability report file '<legal agreement name>_t<tempersture value>.sol.json'

        # Parse the generated smart contract
        self.__parsed_sol = parser.parse_file(self.__path2sol)
        self.__parsed_obj = parser.objectify(self.__parsed_sol)
        self.__no_contracts = len(self.__parsed_obj.contracts.keys())
        self.__no_functions_per_contract = {contract: len(self.__parsed_obj.contracts[contract].functions.keys()) for contract in self.__parsed_obj.contracts.keys()}
        self.__no_functions = sum(self.__no_functions_per_contract.values())

        if path2sol_ref is not None:
            # Parse the reference smart contract if provided
            self.__path2sol_ref = path2sol_ref
            self.__parsed_sol_ref = parser.parse_file(self.__path2sol_ref)
            self.__parsed_obj_ref = parser.objectify(self.__parsed_sol_ref)
            self.__no_contracts_ref = len(self.__parsed_obj_ref.contracts.keys())
            self.__no_functions_per_contract_ref = {contract: len(self.__parsed_obj_ref.contracts[contract].functions.keys()) for contract in self.__parsed_obj_ref.contracts.keys()}
            self.__no_functions_ref = sum(self.__no_functions_per_contract_ref.values())
        else:
            logging.warning("No reference smart contract provided. Skipping BLEU and CodeBLEU score calculation.")

        if os.path.exists(self.__vul_report_file_path):
            self.__vul_report = self.get_vulns(self.__vul_report_file_path)
        else:
            self.run_vulnerability_detection(self.__path2sol)
            self.__vul_report = self.get_vulns(self.__vul_report_file_path)

        ### TODO: Implement later if needed
        # self.compilable = self.is_compilable()
        # self.security = self.is_secure()
        # self.fully_defined = self.is_fully_defined()
        # self.comments = self.has_comments()
        # self.external_calls = self.has_external_calls()
        # self.parameters = self.has_parameters()
        # self.bleu = self.bleu_score()
        # self.code_bleu = self.code_bleu_score()
        
    @property
    def file_name(self):
        return self.__file_name

    @property
    def has_comments(self):
        if len(self.sol_code) < len(self.sol_code_raw):
            return True
        return False
    
    @property
    def no_contracts(self):
        return self.__no_contracts
    
    @property
    def no_functions(self):
        return self.__no_functions
    
    @property
    def no_functions_per_contract(self):
        return self.__no_functions_per_contract
    
    @property
    def sol_code(self):
        return self.__sol_code
    
    @property
    def sol_code_raw(self):
        return self.__sol_code_raw
    
    @property
    def no_contracts_ref(self):
        return self.__no_contracts_ref
    
    @property
    def no_functions_ref(self):
        return self.__no_functions_ref
    
    @property
    def no_functions_per_contract_ref(self):
        return self.__no_functions_per_contract_ref
    
    @property
    def vul_report(self):
        return self.__vul_report
    
    @property
    def is_compilable(self):
        return self.__vul_report['compilable']
    
    @property
    def vul_summary(self):
        return self.__get_vul_summary()
    
    @staticmethod
    def remove_comments(string):
        pattern = r"(\".*?\"|\'.*?\')|(/\*.*?\*/|//[^\r\n]*$)"
        # first group captures quoted strings (double or single)
        # second group captures comments (//single-line or /* multi-line */)
        regex = re.compile(pattern, re.MULTILINE|re.DOTALL)
        def _replacer(match):
            # if the 2nd group (capturing comments) is not None,
            # it means we have captured a non-quoted (real) comment string.
            if match.group(2) is not None:
                return "" # so we will return empty to remove the comment
            else: # otherwise, we will return the 1st group
                return match.group(1) # captured quoted-string
        return regex.sub(_replacer, string)
    
    def run_vulnerability_detection(self, sc_sol: str = None, cmd: list = None):
        """
        Run vulnerability detection tool on given smart contract
        :param cmd: command to run vulnerability detection tool
        :return: vulnerability report
        """
        # Verify if docker is running
        try:
            self.docker_client = docker.from_env()
            self.docker_client.containers.list()
        except Exception as e:
            logging.error(f"Docker is not running. Error: {e}")
            raise e

        # Get docker container instance, else create it
        try:
            container = self.docker_client.containers.get(self.vul_tool['docker_name'])
        except Exception as e:

            container = self.docker_client.containers.run(
                image=self.vul_tool['docker_image'],
                detach=True,
                name=self.vul_tool['docker_name'],
                volumes= {self.vul_tool['host_path']: {'bind': self.vul_tool['container_path'], 'mode': 'rw'}}
            )

        if container.status != 'running':
            logging.debug(f"Container {self.vul_tool['docker_name']} is not running. Starting it...")
            container.start()
            logging.info(f"Container {self.vul_tool['docker_name']} started.")

        # Get smart contract solidity file
        sc_name = os.path.basename(sc_sol)
        with open(sc_sol, 'r') as f:
            sc_txt = f.read()
        
        # Get pragma 
        pattern = r"(^pragma solidity ).{0,2}(\d\.\d+\.\d+)+"
        pragma = re.findall(pattern, sc_txt)[0][1]
        if int(pragma.split(".")[1]) == 4 and int(pragma.split(".")[2]) < 11:
            pragma = "0.4.11"
        logging.info(f"Pragma: {pragma}")

        # Run vulnerability detection tool
        if cmd is None:
            relative_path2sc_sol_in_shared_folder = self.__path2sol.replace(self.vul_tool['host_path'] +'\\', '').replace('\\', '/')
            path2sc_sol_in_shared_folder = '/'.join([self.vul_tool['container_path'], relative_path2sc_sol_in_shared_folder])
            logging.info(f"Path to smart contract in shared folder: {path2sc_sol_in_shared_folder}")
            cmd = self.vul_tool['cmd'](path2sc_sol_in_shared_folder, pragma)
            cmd_err = self.vul_tool['cmd_err'](path2sc_sol_in_shared_folder, pragma)
        
        # Run command
        if isinstance(cmd, list):
            for c in cmd:
                logging.debug(f"Running command: {c}")
                _, output = container.exec_run(cmd=c, stdin=True)
                logging.info(f'Slither output:\n{_}\n{output}')
            
            # If the last output is empty, run the command to check if the smart contract compiles 
            # since the last command did not return a valid JSON
            if output.decode('utf-8') == '':
                for c in cmd_err:
                    logging.debug(f"Compilatin error detected. Running command: {c}")
                    _, output = container.exec_run(cmd=c, stdin=True)
                    logging.info(f'Slither output:\n{_}\n{output}')
        else:
            raise ValueError(f"Command must be a list, not {type(cmd)}")
        try:
            json_out = json.loads(output.decode('utf-8'))
        except Exception as e:
            # TODO: Most likely, this happends when the smart contract is not compilable
            # Try to catch the error "raise 'InvalidCompilation'..." with regex
            logging.error(f"Error while parsing JSON output:\n{e}")
            json_out = {
                "success": False,
                "message": output.decode('utf-8')
            }

        with open(self.__vul_report_file_path, "w") as ff:
            json.dump(json_out, ff, indent=4)
        return output.decode('utf-8')

    def get_vulns(self, vul_report_file: str):
        """
        Get vulnerability report from vulnerability detection tool
        :param cmd: command to run vulnerability detection tool
        :return: vulnerability report
        """
        with open(vul_report_file, "r") as ff:
            vulns_raw = json.load(ff)
            logging.debug(pformat(vulns_raw))
        if self.vul_tool_name == "slither":
            if vulns_raw.get("results", {}).get("detectors", False):
                vulns = {
                    'compilable': vulns_raw['compilable'],
                    'vulns': list(map(lambda x: {key: x[key] for key in ["description", "check", "impact", "confidence","first_markdown_element"]}, 
                                  vulns_raw["results"]["detectors"]))
                }
            else:
                # If vulnerability detectioin tool fails, return the error.
                # Commonly, this happens when the pragma is not supported or the smart contract does not compile
                pattern_not_compilable = r'InvalidCompilation: (.*)'
                logging.error(f"Slither execution failed:\n\n{vulns_raw}")
                vulns = {
                    'compilable': False,
                    'vulns': [{
                        "impact":"High",
                        "confidence":"High",
                        "description": re.findall(pattern_not_compilable, vulns_raw["message"], re.DOTALL)
                    }]
                }
        # Add `elif` with other vulnerability detection tools (i.e., Mythril)
        else:
            raise ValueError(f"Vulnerability tool '{self.vul_tool}' not supported")
        return vulns
    
    def __get_vul_summary(self):
        if self.__vul_report['compilable']:
            occurrences = {}
        for item in self.__vul_report['vulns']:
            key = (item['check'], item['confidence'], item['impact'])
            occurrences[key] = occurrences.get(key, 0) + 1
        return occurrences
