from pipeline.pipeline import Pipeline
from pipeline.prompts import PROMPTS
import os
import logging

# Make sure the user want to run the pipeline with all prompts
confirm = input(f"Run all prompt? (y/n): ")
if confirm.lower() != 'y':
    logging.info("Exiting.")
    exit()
for pr_name, prompt in PROMPTS.items():
    logging.info(f"----------------------------------------------\nRunning {pr_name} prompt.")
    Pipeline.pipe("./test_contracts", vul_tool='slither', model="gpt-4-0125-preview", output_path=os.path.join('output', "gpt-4-0125-preview", pr_name), lambda_prompt=prompt)