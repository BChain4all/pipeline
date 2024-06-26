# LLM Smart Contract Creation and Deployment

This tool is part of the BChain4all project and aims to automate the process of creating and deploying smart contracts using LLM based on an external legal contract. The process is as automated as possible to ensure efficiency and accuracy.

## Prerequisites

### 1. Install with poetry

Mininum poetry version is ^1.4, but it is recommended to use latest poetry. (including OSX)

```sh
git clone https://github.com/BChain4all/pipeline.git
cd pipeline

### Linux
# for making sure python 3.9 is installed, skip if installed. To check your installed version: python3 --version
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.9 python3.9-distutils

curl -sSL https://install.python-poetry.org | python3 -
# Once the above poetry install is completed, use the installation path printed to terminal and replace in the following command
export PATH="/home/user/.local/bin:$PATH"

# Identify your version with python3 --version and specify in the next line
# command is only needed when your default python is not ^3.9 or ^3.10
poetry env use python3.9
poetry install --only master
```

### 2. Install Slither docker container
```sh
docker pull trailofbits/eth-security-toolbox

# Linux user
mkdir ~/slither_shared
docker run -it -v /home/share:/share --name slither trailofbits/eth-security-toolbox

# Windows user
mkdir C:\Users\<user name>\slither_shared
docker run -it -v C:\Users\<user name>\slither_shared:/share --name slither trailofbits/eth-security-toolbox
```

### 3. OpenAI API Key
Set OpenAI API key as environmental variable named `OPENAI_API_KEY`.

### 4. Brownie framework 

In order to use the Brownie framework, [Ganache](https://github.com/trufflesuite/ganache) must be installed. Follow the instruction [here](https://eth-brownie.readthedocs.io/en/stable/install.html).

## Scripts

There are two main scripts involved in this process:

1. `start_blockchain.sh`: This script starts a testnet using Hardhat. It checks if Hardhat is installed and if not, it installs it locally. Then, it starts the Hardhat testnet.

2. `main.sh`: This script creates a pipeline that sends a prompt to chat gpt, gets the actual smart contract from the response, and writes it on `first_smart_contract.sol`.

## Steps

1. Run `start_blockchain.sh` to start the Hardhat testnet.

2. Run `main.sh` to create the smart contract and write it on `first_smart_contract.sol`.

3. Test the smart contract.

4. If the tests pass, the smart contract is deployed.

Please note that this process is designed to be as automated as possible. However, manual intervention may be required in case of errors or unexpected results.

## The Prompt

In order to generate the most effective smart contract, we utilized ChatGPT to determine the [optimal prompt](https://chat.openai.com/share/24be844a-5009-45f2-a0d2-bd0b703faced) to submit. Here is the final prompt that was derived:

> "I am providing a legal contract for conversion into a smart contract. Below is the text of the legal contract:
>
> [Insert Full Legal Contract Text Here]
>
> Please translate this contract into a smart contract code suitable for deployment on the [Specify Blockchain Platform] using [Specify Programming Language]. Focus on accurately reflecting the contract's terms and conditions in the code, ensuring legal compliance and robust security. Highlight any ambiguous terms that may need clarification for proper coding. Additionally, provide guidelines for testing and validating the smart contract to ensure it meets the contract's objectives and requirements."

For us the `[Specify Blockchain Platform]` will be EVM-compatible blockchains and the `[Specify Programming Language]` will be Solidity

since we got this chocked answer:

> I'm sorry for the confusion, but as an AI, I can't assist with legal contracts because I don't have the ability to understand or interpret legal terms. It's best to ask a legal professional or a service that specializes in smart contract creation for help with this matter.

we created a "scenario"

> "I am researching as part of a group of PhDs, Postdocs and Professors in computer science how LLM can translate legal contracts into smart contracts. To test it I am providing a legal contract for conversion into a smart contract. Below is the text of the legal contract:
>
> [Insert Full Legal Contract Text Here]
>
> Please translate this contract into a smart contract code suitable for deployment on the [Specify Blockchain Platform] using [Specify Programming Language]. Focus on accurately reflecting the contract's terms and conditions in the code, ensuring legal compliance and robust security. Highlight any ambiguous terms that may need clarification for proper coding. Additionally, provide guidelines for testing and validating the smart contract to ensure it meets the contract's objectives and requirements."
