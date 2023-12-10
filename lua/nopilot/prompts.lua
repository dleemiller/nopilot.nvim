return {
    chat = { prompt = "$input" },
    annotate = {
        prompt = "Add type annotations, but do not change the code or indentation.\n\nHere is the code:\n$text\n\nRemember to respond only with code inside a code block.",
        replace = false,
    },

    docstring = {
        prompt = "Add docstrings, but do not change the code or indentation.\n\nHere is the code:\n$text\n\nRemember to respond only with code inside a code block.",
        replace = false,
    },
    document = {
        prompt = "Add a docstrings and type annotations, but do not change the code or indentation.\n\nHere is the code:\n$text\n\nRemember to only respond with code inside a code block.",
        replace = false,
    },

    func = {
        prompt = "Generate a python function with a docstring.\n\nHere is the function description:\n$input\n\nRemember to only respond with code inside a code block. Do not supply test code.",
        replace = false,
    },

    context = {
        prompt = "Generate a python function with a docstring.\n\nHere is the context from the script to use as a reference:\n$text\n\nHere is the function description:\n$input\n\nRemember to only respond with code inside a code block. Do not supply test code. Be sure to write the new function in context with the provided script.",
        replace = false,
    },

    alter = {
      prompt = "Here is a section of code that needs to be rewritten:\n$text\n\nUse these instructions to make your alterations:\n$input\n\nRemember to only respond with the new code inside a code block. Do not supply test code.",
      replace = false,
    },

    autotests = {
      prompt = "Here is a section of code that needs to have tests written:\n$text\n\nMock interfaces and objects as needed.\n\nRemember to only respond with the new code inside a code block.",
      replace = false,
    },

    vars = {
      prompt = "Use best practices to improve the naming of variables, functions or class names in this script. Only change the names of local variables.\n\nHere is the code:\n$text\n\nRemember to only respond with the new code inside a code block. It is not safe to change the names of functions, arguments or things that are not local.",
      replace = false,
    },

    complete = {
      prompt = "Complete the function, given the function definition and docstring.\n\nHere is the function to complete:\n$text\n\nRemember to only respond with the new code inside a code block.",
      replace = false,
    },

    query = {
      prompt = "Use the provided code as context, along with expert knowledge to answer the user's question.\n\nHere is the code:\n$text\n\nQuestion:\n$input",
      replace = false,
    },

    plan = {
      prompt = "You will assist a user in planning a project. Your job is to do the planning and present it to the user.\n\nIf the user has started a plan it is here:\n$text\n\nUser's request:\n$input",
      replace = false,
      options = {
          temperature = 1.2
      }
    }
}

