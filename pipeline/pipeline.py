import os
from openai import OpenAI
from pprint import pformat
import tiktoken
import logging
import re
import docker
from .consts import OPENAI, MISTRALAI, GOOGLEAI

# Logging

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s")

# This import must be here to avoid basiConfig of logging to be set to ERROR only
# See. https://github.com/mistralai/client-python/blob/f9b006a94cb9a8624e8509dba4a7082a5f001239/src/mistralai/client_base.py#L17
from mistralai.client import MistralClient
from mistralai.models.chat_completion import ChatMessage

class Pipeline:
    CURR_DIR = os.path.dirname(os.path.realpath(__file__))
    PARENT_DIR = os.path.dirname(CURR_DIR)
    TOKEN_MISTRALAI = os.getenv("MISTRAL_API_KEY")
    TOKEN_GOOGLEAI = os.getenv("GOOGLE_API_KEY")

    def __init__(self, model: str = "gpt-4-0125-preview", output_path: str = 'output'):
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
        if model in OPENAI:
            self.TOKEN_OPENAI = os.getenv("OPENAI_API_KEY")
            self.client = OpenAI(api_key = self.TOKEN_OPENAI)
        elif model in MISTRALAI:
            self.TOKEN_MISTRALAI = os.getenv("MISTRAL_API_KEY")
            self.client = MistralClient(self.TOKEN_MISTRALAI)
        elif model in GOOGLEAI:
            self.TOKEN_GOOGLEAI = os.getenv("GOOGLE_API_KEY")
            # TODO: Add GoogleAI client
            # self.client = None
        else:
            self.TOKEN_OPENAI = os.getenv("OPENAI_API_KEY")
            self.client = OpenAI(api_key = self.TOKEN_OPENAI)
    
    def __call_openai(self, model:str = 'gpt-4-0125-preview', prompt:str=None, temperature: float = 0.1):
        """
        Call OpenAI API
        :param model: model name
        :param prompt: prompt
        :param temperature: temperature
        :return: response
        """
        completions = self.client.chat.completions.create(
                model=model,
                temperature=temperature,
                messages = [
                    {
                        'role': 'user',
                        'content': prompt
                    }
                ]
            )
        new_code = completions.choices[0].message.content
        return new_code
    
    def __call_mistralai(self, model:str = 'mistral-medium', prompt:str=None, temperature: float = 0.1):
        """
        Call MistralAI API
        :param model: model name
        :param prompt: prompt
        :param temperature: temperature (0, 1) # https://docs.mistral.ai/api/
        :return: response
        """
        message = ChatMessage(
            role='user',
            content=prompt,
        )
        response = self.client.chat(
            model=model,
            temperature=temperature,
            message=message
        )
        new_code = response.choices[0].message.content
        return new_code
    
    def get_smart_contract_from_ai(self, prompt, legal_agreement_file_path: str, temperature: float = 0.1, overwrite: bool = False):
        """
        Get smart contract from AI
        :param legal_agreement_file_path: path to legal agreements
        :return: smart contract
        """
        # Get legal agreement
        assert os.path.exists(legal_agreement_file_path), f"Given path for legal agreements'{legal_agreement_file_path}' does not exist"
        # Get legal agreement name
        legal_agreement_name = os.path.basename(legal_agreement_file_path).split(".")[0]
        self.ai_response_raw_path = os.path.join(self.output_dir_raw, legal_agreement_name + f'_t{temperature}_raw.txt')
        self.ai_gen_smart_contract_path = os.path.join(self.output_dir_sc, legal_agreement_name + f'_t{temperature}.sol')

        # 'overwrite' param needed in order to not waste time and money generating the same smart contract
        if os.path.exists(self.ai_gen_smart_contract_path) and not overwrite:
            logging.info(f"Smart contract already generated for '{legal_agreement_name}'")
            with open(self.ai_gen_smart_contract_path, "r", encoding='utf-8') as ff:
                gen_smart_contract = ff.read()
        else:
            with open(legal_agreement_file_path, 'r') as f:
                legal_agreement = f.readlines()
            
            try:
                prompt_str = prompt(legal_agreement)
                # Verify if the prompt exceedes the maximum number of tokens
                enc = tiktoken.encoding_for_model(self.model)
                no_tokens = len(enc.encode(prompt(legal_agreement)))
                logging.info(f"Number of tokens for prompt: {no_tokens}")
                if self.model in OPENAI:
                    new_code = self.__call_openai(model=self.model, prompt=prompt_str, temperature=temperature)
                elif self.model in MISTRALAI:
                    new_code = self.__call_mistralai(model=self.model, prompt=prompt_str, temperature=temperature)
                elif self.model in GOOGLEAI:
                    raise NotImplementedError(f"GoogleAI model '{self.model}' not implemented")
                else:
                    new_code = self.__call_openai(model=self.model, prompt=prompt_str, temperature=temperature)

                # Save raw content for evaluation in the output_path folder as <legal agreement name>_raw.txt
                with open(self.ai_response_raw_path, "w") as ff:
                    ff.write(new_code)

                logging.debug(f"NEW CODE: {new_code}")
                
                code_only_pattern = r"pragma solidity.*}"
                gen_smart_contract = re.search(code_only_pattern, new_code, re.DOTALL).group(0)
                # Save the file with the new Solidity code (hopefully) provided by ChatGPT
                with open(self.ai_gen_smart_contract_path, "w") as ff:
                    ff.write(gen_smart_contract)
            except Exception as e:
                logging.error(f"Error while generating smart contract for '{legal_agreement_name}':\n{e}")
                gen_smart_contract = None

        return gen_smart_contract
    
    @classmethod
    def pipe(cls, legal_agreement_path: str, vul_tool: str = 'slither', model: str = "gpt-4-0125-preview", output_path: str = 'output', temperatures = [0.0, 0.5, 1, 1.5, 2],lambda_prompt: None = lambda x: f"x"):
        # Temperatures accoding to https://arxiv.org/pdf/2309.08221.pdf
        assert os.path.exists(legal_agreement_path), f"Given path for legal agreements'{legal_agreement_path}' does not exist"
        assert os.listdir(legal_agreement_path), f"Given path for legal agreements'{legal_agreement_path}' is empty"

        for file in os.listdir(legal_agreement_path):
            abs_file = os.path.join(legal_agreement_path, file)
            logging.info(f"Processing file '{file}'")
            for temperature in temperatures:
                file_name, _ = os.path.splitext(file)

                inst = cls(vul_tool, model, os.path.join(output_path, file_name))
                sc_gen = inst.get_smart_contract_from_ai(lambda_prompt, temperature=temperature, legal_agreement_file_path=abs_file)
                logging.debug(f"Smart contract generated for '{file}':\n{pformat(sc_gen)}")
        