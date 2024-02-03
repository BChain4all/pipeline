### Prompts following COSTAR guidelines
# Ref. https://www.youtube.com/watch?v=CPsoesktio4

import inspect

CONTEXT = {
    1: "You are a Masters student in Computer Science.",
    2: "You are a junior developer.",
    3: "You are a senior Solidity developer.",
}

REQUIREMENTS = {
    1: "",
    2: """The software requirements are:
    - target blockchain: Ethereum
    - Solidity pragma >0.8
    - fully defined function logic
    - assign value of available parameters
    - ready to deploy
    - compilable
    - secure.""",
}

# Response already in the GOAL ( we want Solidity code)
GOAL = {
    1: "Write a smart contract in Solidity based on the following legal agreement", 
    2: "Write a smart contract in Solidity that reflects payments, conditions, constraint, and termination of the following legal agreement",
}

AUDIENCE = {
    1:"",
    2: "You will deliver the smart contract to your professor.",
    3: "You will deliver the smart contract to your supervisor.",
    4: "You will deliver the smart contract to another senior developer.",
    5: "You will deliver the smart contract to your company's legal department."
}

STYLE = {
    1: "",
    2: "Be creative and use your own style.",
    3: "Be professional and use a formal style.",
}

PROMPTS = {
    # ---------- Masters student
    'PR1': lambda x: f"""
    {CONTEXT[1]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[1]}
    {AUDIENCE[1]}
    """,
    'PR2': lambda x: f"""
    {CONTEXT[1]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[2]}
    {AUDIENCE[2]}
    """,
    'PR3': lambda x: f"""
    {CONTEXT[1]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[3]}
    {AUDIENCE[2]}
    """,
    'PR4': lambda x: f"""
    {CONTEXT[1]} {GOAL[1]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[2]}
    """,
    'PR5': lambda x: f"""
    {CONTEXT[1]} {GOAL[2]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[2]}
    """,
    # ---------- Junior developer
    'PR6': lambda x: f"""
    {CONTEXT[2]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[1]}
    {AUDIENCE[1]}
    """,
    'PR7': lambda x: f"""
    {CONTEXT[2]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[2]}
    {AUDIENCE[3]}
    """,
    'PR8': lambda x: f"""
    {CONTEXT[2]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[3]}
    {AUDIENCE[3]}
    """,
    'PR9': lambda x: f"""
    {CONTEXT[2]} {GOAL[1]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[3]}
    """,
    'PR10': lambda x: f"""
    {CONTEXT[2]} {GOAL[2]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[3]}
    """,
    # ---------- Senior developer
    'PR11': lambda x: f"""
    {CONTEXT[3]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[1]}
    {AUDIENCE[1]}
    """,
    'PR12': lambda x: f"""
    {CONTEXT[3]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[2]}
    {AUDIENCE[4]}
    """,
    'PR13': lambda x: f"""
    {CONTEXT[3]} {GOAL[1]}

    {x}
    {REQUIREMENTS[1]}
    {STYLE[3]}
    {AUDIENCE[4]}
    """,
    'PR14': lambda x: f"""
    {CONTEXT[3]} {GOAL[1]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[4]}
    """,
    'PR15': lambda x: f"""
    {CONTEXT[3]} {GOAL[2]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[4]}
    """,
    # ---------- Senior developer with reward
    'PR16': lambda x: f"""
    {CONTEXT[3]} A company will pay you $500,000 for the completion of the project. {GOAL[2]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[4]}
    """,
    # ---------- Senior developer that delivers to an attorney
    'PR17': lambda x: f"""
    {CONTEXT[3]} A company will pay you $500,000 for the completion of the project. {GOAL[2]}

    {x}
    {REQUIREMENTS[2]}
    {STYLE[3]}
    {AUDIENCE[5]}
    """,
    
}

### Uncomment to get the prompts in a file
# with open('prompt.txt', 'w') as f:
#     for key, val in PROMPTS.items():
#         f.write(f'=============== Prompt {key} ===============')
#         f.write('\n')
#         f.write(inspect.cleandoc(val('<legal agreement>')))
#         f.write('\n')