import os
import pandas as pd
from pprint import pformat
from nltk.translate.bleu_score import sentence_bleu, corpus_bleu
from pprint import pformat
import solcx
import logging
import re
import json
import docker
import nltk

# Logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s")

class SmartCMetrics:
    """This class is responsible for evaluating the quality of the smart contract evaluating the following metrics:
    1- compilability [OK]
    2- security [OK]
    3- number of functions [OK]
    4- number of functions whose logic is fully defined
    5- presence of comments [OK]
    6- presence of external calls [OK]
    7- availability of value for parameters [OK]
    8- BLEU score (if a reference is available)
    9- CodeBLEU score (if a reference is available)
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
        self.__pragma = self.get_pragma(self.__sol_code)
        solcx.install_solc(self.__pragma)

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
        if os.path.exists(self.__vul_report_file_path):
            self.__vul_report = self.get_vulns(self.__vul_report_file_path)
        else:
            self.run_vulnerability_detection(self.__path2sol)
            self.__vul_report = self.get_vulns(self.__vul_report_file_path)
        self.__contracts = self.get_contract_names(self.__sol_code)
        self.__no_contracts = len(self.__contracts)
        self.__external_calls = self.get_external_calls(self.__sol_code)
        self.__no_external_calls = len(self.__external_calls)
        self.__path2sol_ref = path2sol_ref

        if self.is_compilable:
            self.__abi = solcx.compile_source(self.__sol_code, solc_version=self.__pragma) 
            # Parse the generated smart contract
            self.__functions_per_contract = {contract: [abi_item['name'] for abi_item in self.__abi[f"<stdin>:{contract}"]['abi'] if abi_item.get('type', False) == 'function']
                                            for contract in self.__contracts}
            self.__no_functions_per_contract = {contract: len(self.__functions_per_contract[contract]) for contract in self.__functions_per_contract.keys()}
            self.__no_functions = sum(self.__no_functions_per_contract.values())
        else:
            logging.warning("Smart contract does not compile. Skipping BLEU and CodeBLEU score calculation.")
            self.__abi = {}
            self.__functions_per_contract = {}
            self.__no_functions_per_contract = {}
            self.__no_functions = 0

        if path2sol_ref is not None:
            # Parse the reference smart contract if provided
            self.__path2sol_ref = path2sol_ref
            with open(self.__path2sol_ref, 'r') as f:
                self.__sol_code_raw_ref = f.read()

            self.__sol_code_ref = self.remove_comments(self.__sol_code_raw_ref)
            self.__pragma_ref = self.get_pragma(self.__sol_code_ref)
            # solcx.install_solc(self.__pragma_ref)
            # self.__abi_ref = solcx.compile_source(self.__sol_code_ref, solc_version=self.__pragma_ref)
            # self.__file_name = os.path.basename(path2sol) # <legal agreement name>_t<tempersture value>.sol
            # # Parse the generated smart contract
            # self.__contracts_ref = self.get_contract_names(self.sol_code_ref)
            # self.__external_calls_ref = self.get_external_calls(self.sol_code_ref)
            # self.__no_external_calls_ref = len(self.__external_calls_ref)
            # self.__no_contracts_ref = len(self.__contracts_ref)
            # self.__functions_per_contract_ref = {contract: [abi_item['name'] for abi_item in self.__abi_ref[f"<stdin>:{contract}"]['abi'] if abi_item.get('type', False) == 'function']
            #                                     for contract in self.__contracts_ref}
            # self.__no_functions_per_contract_ref = {contract: len(self.__functions_per_contract_ref[contract]) for contract in self.__functions_per_contract_ref.keys()}
            # self.__no_functions = sum(self.__no_functions_per_contract_ref.values())

            
        else:
            logging.warning("No reference smart contract provided. Skipping BLEU and CodeBLEU score calculation.")
        
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

    @property
    def get_parsed_sol(self):
        return self.__parsed_sol
    
    @property
    def get_parsed_obj(self):
        return self.__parsed_obj
    
    @property
    def param_with_initial_value(self):
        return self.__get_param_with_initial_value()
    
    @property
    def no_param_with_initial_value(self):
        return self.__get_no_param_with_initial_value()
    
    @property
    def external_calls(self):
        return self.__external_calls
    
    @property
    def no_external_calls(self):
        return self.__no_external_calls
    
    @property
    def get_pragma(self):
        return self.__pragma
    
    @property
    def vul_count(self):
        return self.__get_vul_count()

    @property 
    def pragma(self):
        return self.__pragma
    
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
        with open(sc_sol, 'r') as f:
            sc_txt = f.read()
        
        # Get pragma 
        pragma = self.get_pragma(sc_txt)
        self.__pragma = pragma
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
                    'compilable': True,
                    'vulns': list(map(lambda x: {key: x[key] for key in ["description", "check", "impact", "confidence","first_markdown_element"]}, 
                                  vulns_raw["results"]["detectors"]))
                }
            else:
                # If vulnerability detectioin tool fails, return the error.
                # Commonly, this happens when the pragma is not supported or the smart contract does not compile
                pattern_not_compilable = r'InvalidCompilation: (.*)'
                logging.error(f"Slither execution failed:\n\n{pformat(vulns_raw)}")
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
    
    def __compute_bleu(self):
        if self.__path2sol_ref is not None:
            # Compute BLEU score
            tk_code =  nltk.tokenize.sent_tokenize(self.__sol_code)
            tk_code_ref = nltk.tokenize.sent_tokenize(self.__sol_code_ref) 
            return nltk.translate.bleu_score.sentence_bleu([tk_code_ref], tk_code)

        return None
    
    @staticmethod
    def get_pragma(sc_txt):
        # Get pragma 
        pattern = r"(pragma solidity ).{0,2}(\d\.\d+\.\d+)+"
        pragma = re.findall(pattern, sc_txt)[0][1]
        if int(pragma.split(".")[1]) == 4 and int(pragma.split(".")[2]) < 11:
            pragma = "0.4.11"
        return pragma
    
    def __get_vul_summary(self):
        if self.__vul_report['compilable']:
            occurrences = {}
            for item in self.__vul_report['vulns']:
                key = (item['check'], item['confidence'], item['impact'])
                occurrences[key] = occurrences.get(key, 0) + 1
        else:
            occurrences = {
                ('Compilation error', 'High', 'High'): 1
            }
        return occurrences
    
    def __get_vul_count(self):
        to_return = {
                'high': 0,
                'medium': 0,
                'low': 0
            }
        if self.__vul_report['compilable']:
            occurrences = self.__get_vul_summary()
            for key, val in occurrences.items():
                check, conf, impact = key
                if impact == 'High':
                    to_return['high'] += val
                elif impact == 'Medium':
                    to_return['medium'] += val
                elif impact == 'Low':
                    to_return['low'] += val
            return to_return

    def __get_param_with_initial_value(self):
        # Execute the function only if the smart contract is compilable
        if self.__vul_report['compilable']:
            valued_param = {contract: [] for contract in self.__contracts}
            for contract in self.__contracts:
                nodes = self.__abi[f'<stdin>:{contract}']['ast']['nodes'][1]['nodes']
                for node in nodes:
                    # if node.get('constant', False):
                    if node.get('name', False):
                        valued_param[contract].append((node['name'], node['value']['value'] if node.get('value', False) else None))
            return valued_param
        return {}
    
    def __get_no_param_with_initial_value(self):
        count = 0
        if self.__vul_report['compilable']:
            valued_param = self.__get_param_with_initial_value()
            for contract, valued_list in valued_param.items():
                for name, value in valued_list:
                    if value is not None:
                        count += 1
        return count
    
    @staticmethod
    def get_contract_names(sol_txt: str):
        pattern_contract = 'contract (.*) {'
        return re.findall(pattern_contract, sol_txt)
    
    @staticmethod
    def get_external_calls(sol_txt: str):
        # If there are any imports, the smart contract has external calls
        pattern_contract = 'import (.*);'
        return re.findall(pattern_contract, sol_txt)

    @classmethod
    def get_sc_metrics(cls, path2sol: str, vul_tool: str = 'slither', path2sol_ref: str = None):
        """Get smart contract metrics
        :param path2sol: path to smart contract
        :param vul_tool: vulnerability detection tool
        :param path2sol_ref: path to reference smart contract
        :return: smart contract metrics
        """

        def compute_scores(metrics: dict, weights: dict):
            score = {'compilable': 0}
            if metrics['compilable']:
                for key, val in weights.items():
                    if isinstance(val, dict):
                        for k, v in val.items():
                            score[f'{key}_score'] = metrics[key][k] * v
                    else:
                        if key == 'pragma':
                            score[f'{key}_score'] = val(metrics[key])
                        else:
                            score[f'{key}_score'] = metrics[key] * val
            return score

        sc = cls(path2sol, vul_tool, path2sol_ref)

        weights = {
            'compilable': 1,
            'vul_count': {
                'high': -1,
                'medium': -0.5,
                'low': -0.25
            },
            'has_comments': 0.5,
            'no_param_with_initial_value': 0.5,
            'no_contracts': 0.25,
            'no_functions': 0.15,
            # 'no_external_calls': 0.5,
            'pragma': lambda x: 1 if x.split('.')[1] == '8' else 0
        }

        metrics = {
            'compilable': sc.is_compilable,
            'name': sc.file_name,
            'pragma': sc.pragma,
            'no_pragma': int(sc.pragma.split(".")[1]),
            'temperature': re.findall(r"_t(.*).sol", sc.file_name)[0] if re.findall(r"_t(.*).sol", sc.file_name) else 'N/A',
            'vul_report': sc.vul_report,
            'vul_summary': sc.vul_summary,
            'vul_count': sc.vul_count,
            'no_contracts': sc.no_contracts if sc.is_compilable else 0,
            'no_functions': sc.no_functions if sc.is_compilable else 0,
            'no_functions_per_contract': sc.no_functions_per_contract if sc.is_compilable else 0,
            'has_comments': sc.has_comments,
            'external_calls': sc.external_calls if sc.is_compilable else 0,
            'no_external_calls': sc.no_external_calls if sc.is_compilable else 0,
            'param_with_initial_value': sc.param_with_initial_value if sc.is_compilable else 0,
            'no_param_with_initial_value': sc.no_param_with_initial_value if sc.is_compilable else 0,
            # 'bleu': sc.__compute_bleu(),
            # 'code_bleu': self.code_bleu_score
        }
        scores = compute_scores(metrics, weights)
        metrics.update(scores)
        metrics.update({'total_score': sum(scores.values())})
        return metrics



    @classmethod
    def pipe(cls, pipe_output_path: str, vul_tool: str = 'slither', path2sol_ref: str = None):
        """Post-processing pipeline

        Parameters
        ----------
        pipe_output_path : str
            The root path of the pipeline output
        vul_tool : str, optional
            Vulnerability tool to use, by default 'slither'
        path2sol_ref : str, optional
            Reference smart contract to compute BLEU and CodeBLEU metrics, by default None

        """
        ### Path created by the pipeline
        # C:\Users\<user name>\slither_shared
        # |   
        # \---output
        #     |   
        #     +---<LLM model name>
        #     |   +---<n_iter>
        #     |   |     +---<prompt key>
        #     |   |     |   |   
        #     |   |     |   +---<legal agreement name>
        #     |   |     |   |    +---raw
        #     |   |     |   |    |       <legal agreement name>_t<temperature value>_raw.txt
        #     |   |     |   |    |       .
        #     |   |     |   |    |       .
        #     |   |     |   |    |       
        #     |   |     |   |    +---sc
        #     |   |     |   |    |       <legal agreement name>_t<temperature value>.sol
        #     |   |     |   |    |       .
        #     |   |     |   |    |       .
        #     |   |     |   |    |       
        #     |   |     |   |    \---vul
        #     .   .     .   .

        for model_name_path in os.listdir(pipe_output_path):
            model_path = os.path.join(pipe_output_path, model_name_path)
            logging.info("=====================================")
            logging.info(f"Model path: {model_path}")
            if os.path.isdir(model_path):
                for n_test_name in os.listdir(model_path):
                    n_test_path = os.path.join(model_path, n_test_name)
                    logging.info(f"    -> n_test path: {n_test_path}")
                    to_pandas = []
                    if os.path.isdir(n_test_path):
                        for prompt_name_path in os.listdir(n_test_path):
                            prompt_path = os.path.join(n_test_path, prompt_name_path)
                            logging.info(f"        -> Prompt path: {prompt_path}")
                            if os.path.isdir(prompt_path):
                                for legal_agreement_name_path in os.listdir(prompt_path):
                                    legal_agreement_path = os.path.join(prompt_path, legal_agreement_name_path)
                                    logging.info(f"            -> Legal agreement name path: {legal_agreement_path}")
                                    if os.path.isdir(legal_agreement_path):
                                        legal_agreement_sc_path = os.path.join(legal_agreement_path, 'sc')
                                        for sol_name_path in os.listdir(legal_agreement_sc_path):
                                            sol_path = os.path.join(legal_agreement_sc_path, sol_name_path)
                                            logging.info(f"                -> Smart contract path: {sol_path}")
                                            if os.path.isfile(sol_path):
                                                sc_sol_metrics = SmartCMetrics.get_sc_metrics(sol_path, vul_tool, path2sol_ref)
                                                sc_sol_metrics.update({'prompt': prompt_name_path})
                                                sc_sol_metrics.update({'legal_agreement': legal_agreement_name_path})
                                                to_pandas.append(sc_sol_metrics)
                                            else:
                                                logging.warning(f"                ->Path '{sol_path}' is not a file")
                                    else:
                                        logging.warning(f"            -> Path '{legal_agreement_path}' is not a directory")
                    data = pd.DataFrame(to_pandas)
                    if not data.empty:
                        logging.info(f"        -> Metrics:{data}")
                        data.set_index(['prompt', 'legal_agreement'], inplace=True)
                        where_to_save = os.path.join(model_path, f'sc_metrics_{model_name_path}_{n_test_name}.xlsx')
                        data.to_excel(where_to_save, index=True, header=True)
                        logging.info(f"        -> Metrics saved to {where_to_save}")