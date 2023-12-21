return {
    alter = {
      prompt = "Here is a section of code that needs to be rewritten:\n$visual\n\nUse these instructions to make your alterations:\n$user\n\nRemember to only respond with the new code inside a code block. Do not supply test code.",
      description = "alter the selection",
      replace = false,
    },
    chat = {
        prompt = "$user",
        replace = false,
        description = "user message only",
        system = "You are a helpful expert programmer and teacher.",
    },
    complete = {
      prompt = "Complete the function, given the function definition and docstring.\n\nHere is the function to complete:\n$visual\n\nRemember to only respond with the new code inside a code block.",
      description="complete the function from docstring and def",
      replace = false,
    },
    debug = {
        prompt = "Identify bugs in the following code:\n\n$visual",
        replace = false,
        description = "find bugs in selection",
    },
    document = {
        prompt = "Add a docstrings and type annotations, but do not change the code or indentation.\n\nHere is the code:\n$visual\n\nRemember to only respond with code inside a code block.",
        replace = false,
        description = "apply documentation to selection",
    },
    query = {
      prompt = "Use the provided code as context, along with expert knowledge to answer the user's question.\n\nHere is the code:\n$visual\n\nQuestion:\n$user",
      replace = false,
      description = "ask a question about selection",
    },
}

