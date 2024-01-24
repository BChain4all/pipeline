# LLM Smart Contract Creation and Deployment

This project aims to automate the process of creating and deploying smart contracts using LLM based on an external legal contract. The process is as automated as possible to ensure efficiency and accuracy.

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
