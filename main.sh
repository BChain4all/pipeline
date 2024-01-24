# this script creates a pipeline

# create the first prompt for chat gpt
prompt=""
contr="./"
file=$(cat $contr)
prompt_file="$prompt\n$file"

# sends the first prompt to chat gpt
chatgpt -p "$prompt_file" >> first_step.txt

# from file first_step.txt get the actual smart contract and write it on first_smart_contract.sol