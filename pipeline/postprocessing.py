import os
from nltk.translate.bleu_score import sentence_bleu, corpus_bleu
from pprint import pprint
from solidity_parser import parser

path_to_sol = r"C:\Users\emanuele\slither_shared\output\PR1\LeaseAgreement03\sc\LeaseAgreement03_t0.1.sol"
parsed = parser.parse_file(path_to_sol)
parsed_obj = parser.objectify(parsed)

# Count number of contracts
no_contracts = parsed_obj.contracts.keys()

# Count number of functions
no_functions_per_contract = {contract: len(parsed_obj.contracts[contract].functions.keys()) for contract in no_contracts}

print(f"Number of contracts: {len(no_contracts)}")
print(f"Number of functions per contract: {no_functions_per_contract}")