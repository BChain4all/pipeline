# Goal of this script is to start a testnet using hardhat
echo "Starting Hardhat testnet..."

# Check if hardhat is installed, otherwise install it locally
if ! command -v npx &> /dev/null
then
    echo "npx could not be found, installing..."
    npm install npx -g
fi

if ! npx hardhat &> /dev/null
then
    echo "Hardhat could not be found, installing locally..."
    npm install --save-dev hardhat
fi

# Start hardhat testnet
echo "Starting Hardhat testnet..."
npx hardhat node
