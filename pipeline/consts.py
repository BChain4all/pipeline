""" Differentiate between different models

References
----------
1. OpenAI
    - https://platform.openai.com/docs/models/gpt-4-and-gpt-4-turbo
2. MistralAI
    - https://docs.mistral.ai/platform/endpoints/
3. GoogleAI
    - https://ai.google.dev/models/gemini
    - https://ai.google.dev/models/palm
    - https://ai.google.dev/tutorials/python_quickstart
    - https://ai.google.dev/palm_docs/text_quickstart

"""
OPENAI = [
    'gpt-4-0125-preview',
    'gpt-4-turbo-preview',
    'gpt-4-1106-preview',
    'gpt-4-vision-preview',
    'gpt-4',
    'gpt-4-0613',
    'gpt-4-32k',
    'gpt-4-32k-0613',
    'gpt-3.5-turbo-1106',
    'gpt-3.5-turbo',
    'gpt-3.5-turbo-16k',
    'gpt-3.5-turbo-instruct',
    'gpt-3.5-turbo-0613',
    'gpt-3.5-turbo-16k-0613',
    'gpt-3.5-turbo-0301',
]

MISTRALAI = [
    'mistral-tiny',
    'mistral-small',
    'mistral-medium',
]

GOOGLEAI = [
    'gemini-pro',
    # Optional, add PaLM 2
]