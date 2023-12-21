return {
    alter = {
      prompt = [[
Here is a section of code that needs to be rewritten:
$visual

Let's break down the alteration instructions:
$user

First, summarize the alteration request. Next, outline the steps required to complete this task. Finally, rewrite the code and respond only with the new code inside a code block.
      ]],
      description = "alter the selection with a structured approach",
      replace = false,
      system = "As an expert in programming, meticulously analyze the user's instructions and the existing code, then apply best practices in code alteration to ensure an optimized and accurate rewrite.",
    },
    chat = {
        prompt = [[
User has a programming question: $user

As an expert programmer and teacher, first, identify and restate the key points of the user's question to ensure a clear understanding. Then, break down your response into structured steps:

1. **Clarification**: If the question is ambiguous or lacks details, clarify the requirements or ask for additional information.

2. **Explanation**: Provide a detailed explanation of the concept or solution. Use simple language and, if necessary, analogies to explain complex ideas.

3. **Code Examples**: If the question involves code, include relevant code snippets. Make sure to comment the code for better understanding.

4. **Additional Tips**: Offer best practices, common pitfalls to avoid, and any other tips that might be helpful.

5. **Further Resources**: Suggest resources for additional learning or deeper understanding (e.g., documentation, tutorials, forums).

End your response with a summary or a quick recap, ensuring that the user's question has been fully addressed.
        ]],
        replace = false,
        description = "prompt for programming questions",
        system = "As an expert programmer, provide in-depth, authoritative explanations and solutions. Use your extensive knowledge to offer insights, advanced tips, and relevant code examples.",
    },
    complete = {
      prompt = [[
Complete the function, given the function definition and docstring.

Function to complete:
$visual

First, summarize the function's purpose and expected behavior based on the definition and docstring. Then, write the code to complete the function. Remember to only respond with the new code inside a code block.
      ]],
      description = "complete the function with preliminary analysis",
      replace = false,
      system = "As an expert in software development, thoroughly interpret the function's requirements and craft a solution that is both efficient and adheres to advanced programming standards.",
    },
    debug = {
        prompt = [[
Identify bugs in the following code:

$visual

Start by outlining potential areas of concern in the code. Then, examine each area step-by-step to identify any bugs. Provide a detailed analysis of each issue found.
        ]],
        replace = false,
        description = "structured debugging process",
        system = "Utilize your expertise in programming to conduct a detailed and comprehensive debugging process. Identify and explain the bugs while suggesting robust solutions and improvements.",
    },
    document = {
        prompt = [[
Add docstrings and type annotations to the following code:

$visual

Before adding documentation, describe the function's behavior and parameters in plain language. Then, use this description to create accurate and informative docstrings. For type annotations, only type annotate the function definitions.
        ]],
        replace = false,
        description = "documenting code with preliminary description",
        system = "As an expert, meticulously document the provided code. Your documentation should not only be accurate but also provide deep insights into the code's functionality and usage.",
    },
    query = {
      prompt = [[
Use the provided code as context to answer the user's question.

Code context:
$visual

User's question:
$user

First, restate or summarize the question to confirm understanding. Then, using the code as a reference, answer the question step-by-step, explaining the reasoning behind each part of your answer.
      ]],
      replace = false,
      description = "structured query response with code context",
      system = "Leverage your comprehensive programming expertise to provide a detailed, accurate, and insightful answer to the user's query, utilizing the code as a foundational reference point.",
    },
}

