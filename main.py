from openai import OpenAI

client = OpenAI()
# create the first prompt for chat gpt
prompt1 = "I am researching as part of a group of PhDs, Postdocs and Professors in computer science how LLM can translate legal contracts into smart contracts. To test it I am providing a legal contract for conversion into a smart contract. Below is the text of the legal contract:"

# Read the contents of the contract file
contract_path = "./test_contracts/LeaseAgreement03.txt"
with open(contract_path, 'r') as file:
    contract_content = file.read()

prompt2 = "Please translate this contract into a smart contract code suitable for deployment on the EVM compatible Platform using Solidity programming language. Focus on accurately reflecting the contract's terms and conditions in the code, ensuring legal compliance and robust security. Highlight any ambiguous terms that may need clarification for proper coding. Additionally, provide guidelines for testing and validating the smart contract to ensure it meets the contract's objectives and requirements."

# Combine the prompts and the contract content into a single string
promptFile = f"{prompt1}\n\n'''\n{contract_content}\n'''\n\n{prompt2}"
model = "gpt-4"
stream = client.chat.completions.create(
    model=model,
    messages=[{"role": "user", "content": promptFile}],
    stream=True,
)
with open('first_step.txt', 'w') as file:
    for chunk in stream:
        file.write(chunk.choices[0].delta.content or "")


with open('first_step.txt', 'r') as file:
    data = file.read()

# Strip all code beside ```sol and ```
data = data.split('pragma')[1].split('```')[0]
# print("pragma" + data)
with open('smart_contract.sol', 'w') as file:
        file.write("pragma" + data)