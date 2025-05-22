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

2. Run `main.py` to generate smart contracts starting from the `.txt` documents placed in `test_contract_txt/` folde.

## Publications

* [Leveraging Large Language Models for Automatic Smart Contract Generation](https://ieeexplore.ieee.org/abstract/document/10633392), Emanuele A. Napoli; Fadi Barbàra; Valentina Gatteschi; Claudio Schifanella - [COMPSAC '24](https://ieeecompsac.computer.org/2024/program/)

* [Automatic Smart Contract Generation Through LLMs:
When The Stochastic Parrot Fails](https://ceur-ws.org/Vol-3791/paper5.pdf), Fadi Barbàra; Emanuele A. Napoli; Valentina Gatteschi; Claudio Schifanella - [DLT '24](https://dlt2024.di.unito.it/program/)

