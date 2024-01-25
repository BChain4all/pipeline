# this script creates a pipeline

# create the first prompt for chat gpt
prompt1="I am researching as part of a group of PhDs, Postdocs and Professors in computer science how LLM can translate legal contracts into smart contracts. To test it I am providing a legal contract for conversion into a smart contract. Below is the text of the legal contract:"


contr="./test_contracts/LeaseAgreement03.txt"
file=$(cat $contr)

prompt2="Please translate this contract into a smart contract code suitable for deployment on the EVM compatible Platform using Solidity programming language. Focus on accurately reflecting the contract's terms and conditions in the code, ensuring legal compliance and robust security. Highlight any ambiguous terms that may need clarification for proper coding. Additionally, provide guidelines for testing and validating the smart contract to ensure it meets the contract's objectives and requirements."


promptFile="$prompt1\n\n'''\n$file\n'''\n\n$prompt2"

# sends the first prompt to chat gpt
# chatgpt -q $prompt1  
echo $promptFile |pbcopy
# chatgpt -q \"\"\"promptFile\"\"\"\  >> first_step.txt
# echo "$prompt_file"

# from file first_step.txt get the actual smart contract and write it on first_smart_contract.sol