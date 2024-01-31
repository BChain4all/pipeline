PROMPTS = {
    'PR1': lambda x: f"""
    Write a smart contract in Solidity based on the following legal agreement

    {x}
    """,
    'PR2': lambda x: f"""
    You are a senior Solidity developer. Your next task is to write a smart contract that models and reflects the following legal agreement

    {x}
    """,
    'PR3': lambda x: f"""
    Write a Solidity smart contract with the following requirements: (detailed instruction based)

    - target blockchain: Ethereum
    - Solidity pragma >0.8
    - fully defined function logic
    - assign value of available parameters
    - ready to deploy
    - that reflects the following legal agreement

    {x}
    """,
    'PR4': lambda x: f"""
    ...

    {x}
    """,
    'PR5': lambda x: f"""
    ...

    {x}
    """,
}