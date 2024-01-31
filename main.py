from pipeline.pipeline import Pipeline
from pipeline.prompts import PROMPTS
import os

prompt1 = PROMPTS['PR1']

Pipeline.pipe("./test_contracts", vul_tool='slither', model='gpt-4', output_path=os.path.join('output', 'PR1'), temperatures=[0.1, 0.5], lambda_prompt=prompt1)