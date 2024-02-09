from pipeline.pipeline import Pipeline
from pipeline.prompts import PROMPTS
from pipeline.postprocessing import SmartCMetrics
import os
import logging

## Automatic smart contract generation
# Make sure the user want to run the pipeline with all prompts
confirm = input(f"Run all prompt? (y/n): ")
if confirm.lower() != 'y':
    logging.info("Exiting.")
    exit()

# Temperature test
Pipeline.pipe("./test_contracts", model="gpt-4-0125-preview", output_path=os.path.join('output', "gpt-4-0125-preview", 'Preliminar', pr_name), lambda_prompt=prompt)


# Fixed temperature 0.5, evaluate 4 shots
n_iter = 4

for i in range(1, n_iter+1):
    for pr_name, prompt in PROMPTS.items():
        logging.info(f"----------------------------------------------\nRunning {pr_name} prompt.")
        Pipeline.pipe("./test_contracts", model="gpt-4-0125-preview", output_path=os.path.join('output', "gpt-4-0125-preview", str(i), pr_name), temperatures=[0.5], lambda_prompt=prompt)



### Post-processing
SmartCMetrics.pipe(os.path.join(os.path.expanduser('~'), 'slither_shared', 'output'))    
