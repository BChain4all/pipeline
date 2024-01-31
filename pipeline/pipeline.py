import os
from openai import OpenAI
import tiktoken
import logging
import re
import json
import docker

# Logging

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s")

class Pipeline:
    CURR_DIR = os.path.dirname(os.path.realpath(__file__))
    PARENT_DIR = os.path.dirname(CURR_DIR)
    TOKEN_OPENAI = os.getenv("OPENAI_API_KEY")

    # Define vulnerability tools
    VUL_TOOLS = {
        "slither": {
            "docker_name": "slither",
            "docker_image": "trailofbits/eth-security-toolbox",
            "host_path": os.path.join(os.path.expanduser('~'), 'slither_shared' ),
            "container_path": "/share",
            "cmd": lambda sol_file, pragma: [f"solc-select install {pragma}", f"solc-select use {pragma}", f"slither {sol_file} --json-type console"]
        },
        # Other vulnerability detection tools can be added
    }

    def __init__(self, legal_agreement_path: str, vul_tool: str = 'slither', model: str = "gpt-4", output_path: str = 'output'):
        assert os.path.exists(legal_agreement_path), f"Given path for legal agreements'{legal_agreement_path}' does not exist"
        assert os.listdir(legal_agreement_path), f"Given path for legal agreements'{legal_agreement_path}' is empty"
        self.vul_tool_name = vul_tool
        self.vul_tool = self.VUL_TOOLS[self.vul_tool_name]
        self.output_path = output_path
        self.output_dir = os.path.join(self.vul_tool['host_path'], output_path)
        self.output_dir_raw = os.path.join(self.output_dir, "raw")
        self.output_dir_sc = os.path.join(self.output_dir, "sc")
        self.output_dir_vul = os.path.join(self.output_dir, "vul")
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        if not os.path.exists(self.output_dir_raw):
            os.makedirs(self.output_dir_raw)
        if not os.path.exists(self.output_dir_sc):
            os.makedirs(self.output_dir_sc)
        if not os.path.exists(self.output_dir_vul):
            os.makedirs(self.output_dir_vul)
        self.docker_client = docker.from_env()
        self.model = model
        self.client = OpenAI(api_key = self.TOKEN_OPENAI)

    def run_vulnerability_detection(self, sc_sol: str = None, cmd: list = None):
        """
        Run vulnerability detection tool on given smart contract
        :param cmd: command to run vulnerability detection tool
        :return: vulnerability report
        """

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
        regex = re.search(pattern, sc_txt)
        # pragma = regex.group(0)[1:-1] if regex.group().startswith('^') else str(regex.group(0)[:-1])
        pragma = re.findall(pattern, sc_txt)[0][1]
        logging.debug(f"Pragma: {pragma}")
        if int(pragma.split(".")[1]) == 4 and int(pragma.split(".")[2]) < 11:
            pragma = "0.4.11"
        logging.info(f"Pragma: {pragma}")

        # Run vulnerability detection tool
        if cmd is None:
            path2sc_sol_in_shared_folder = '/'.join([self.vul_tool['container_path'], self.output_path.replace('\\', '/'), 'sc', sc_name])
            logging.info(f"Path to smart contract in shared folder: {path2sc_sol_in_shared_folder}")
            cmd = self.vul_tool['cmd'](path2sc_sol_in_shared_folder, pragma)
        
        # Run command
        if isinstance(cmd, list):
            for c in cmd:
                logging.debug(f"Running command: {c}")
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
            json_out = {"error": output.decode('utf-8')}

        with open(os.path.join(self.output_dir_vul, sc_name + '.json'), "w") as ff:
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
        if self.vul_tool_name == "slither":
            if vulns_raw.get("results", {}).get("detectors", False):
                vulns = list(map(lambda x: {key: x[key] for key in ["description", "check", "impact", "confidence","first_markdown_element"]}, 
                                 vulns_raw["results"]["detectors"]))
                logging.debug(vulns_raw)
            else:
                # If vulnerability detectioin tool fails, return the error.
                # Commonly, this happens when the pragma is not supported or the smart contract does not compile
                logging.error(f"Slither execution failed:\n\n{vulns_raw}")
                vulns = [{
                        "impact":"High",
                        "confidence":"High",
                        "description": vulns_raw["error"].replace("\n", "")
                        }]
        # Add `elif` with other vulnerability detection tools (i.e., Mythril)
        else:
            raise ValueError(f"Vulnerability tool '{self.vul_tool}' not supported")
        return vulns
    
    def get_smart_contract_from_ai(self, prompt, legal_agreement_path: str, temperature: float = 0.1):
        """
        Get smart contract from AI
        :param legal_agreement_path: path to legal agreements
        :return: smart contract
        """
        # Get legal agreement
        assert os.path.exists(legal_agreement_path), f"Given path for legal agreements'{legal_agreement_path}' does not exist"

        # Get legal agreement name
        legal_agreement_name = os.path.basename(legal_agreement_path).split(".")[0]
        with open(legal_agreement_path, 'r') as f:
            legal_agreement = f.readlines()
        
        # Verify if the prompt exceedes the maximum number of tokens
        enc = tiktoken.encoding_for_model(self.model)
        no_tokens = len(enc.encode(prompt(legal_agreement)))
        logging.info(f"Number of tokens for contract '{legal_agreement_name}': {no_tokens}")
        try:
            completions = self.client.chat.completions.create(
                model=self.model,
                temperature=temperature,
                messages = [
                    {
                        'role': 'user',
                        'content': prompt(legal_agreement)
                    }
                ]
            )
            new_code = completions.choices[0].message.content

            # Save raw content for evaluation in the output_path folder as <legal agreement name>_raw.txt
            with open(os.path.join(self.output_dir_raw, legal_agreement_name + f'_t{temperature}_raw.txt'), "w") as ff:
                ff.write(new_code)

            logging.debug(f"NEW CODE: {new_code}")
            
            code_only_pattern = r"pragma solidity.*}"
            gen_smart_contract = re.search(code_only_pattern, new_code, re.DOTALL).group(0)
            # Save the file with the new Solidity code (hopefully) provided by ChatGPT
            with open(os.path.join(self.output_dir_sc, legal_agreement_name + f'_t{temperature}.sol'), "w") as ff:
                ff.write(gen_smart_contract)
        except Exception as e:
            logging.error(f"Error while generating smart contract for '{legal_agreement_name}':\n{e}")
            gen_smart_contract = None

        return gen_smart_contract
    
    @classmethod
    def pipe(cls, legal_agreement_path: str, vul_tool: str = 'slither', model: str = "gpt-4", output_path: str = 'output', temperatures = [0, 0.5, 1, 1.5, 2],lambda_prompt: None = lambda x: f"x"):
        # Temperatures accoding to https://arxiv.org/pdf/2309.08221.pdf
        for file in os.listdir(legal_agreement_path):
            abs_file = os.path.join(legal_agreement_path, file)
            logging.info(f"Processing file '{file}'")
            for temperature in temperatures:
                file_name, _ = os.path.splitext(file)
                file_sol = file_name + f'_t{temperature}.sol'

                inst = cls(legal_agreement_path, vul_tool, model, os.path.join(output_path, file_name))
                # sc_gen = 'ok'
                sc_gen = inst.get_smart_contract_from_ai(lambda_prompt, temperature=temperature, legal_agreement_path=abs_file)
                if sc_gen is not None:
                    
                    inst.run_vulnerability_detection(os.path.join(inst.output_dir_sc, file_sol))
                    inst.get_vulns(os.path.join(inst.output_dir_vul, file_sol + '.json'))
                else:
                    logging.error(f"Smart contract generation failed for '{file}'")
        