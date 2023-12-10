# nopilot.nvim

A fork of the teriffic plugin from David-Kunz `gen.nvim`.

Development in progress...

## Added features (2023/12/09):
- Add API options
- Use visual select in buffer window and hit enter for replace
- Use visual select in buffer window and hit 't' for new tab
## Added (2023/12/10):
- Abstract ollama backend

## Requires

- [Ollama](https://ollama.ai/) with an appropriate model, e.g. [`mistral`](https://ollama.ai/library/mistral) or [`zephyr`](https://ollama.ai/library/zephyr) (customizable)
- [Curl](https://curl.se/)

## Install

Install with your favorite plugin manager, e.g. [lazy.nvim](https://github.com/folke/lazy.nvim)

Example with Lazy

```lua
-- Minimal configuration
{ "dleemiller/nopilot.nvim" },

```

```lua

-- Custom Parameters (with defaults)
{
    "dleemiller/nopilot.nvim",
    opts = {
        backend = {
            name = "ollama",
            config = {
                host = "flint",
                port = 11434,
                model = "deepseek-coder:6.7b-instruct-q6_K"
            }
        },
        display_mode = "float", -- The display mode. Can be "float" or "split".
        show_prompt = false, -- Shows the Prompt submitted to Ollama.
        show_model = false, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = false, -- Never closes the window automatically.
        init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
        debug = false -- Prints errors and the command which is run.
    }
},
```

Here are all [available models](https://ollama.ai/library).

Alternatively, you can call the `setup` function:

```lua
require('nopilot').setup({
  -- same as above
})
```



## Usage

Use command `Np` to generate text based on predefined and customizable prompts.

Example key maps:

```lua
vim.keymap.set({ 'n', 'v' }, '<leader>]', ':<CR>')
```

You can also directly invoke it with one of the [predefined prompts](./lua/nopilot/prompts.lua):

```lua
vim.keymap.set('v', '<leader>]', ':Np alter<CR>')
```

Once a conversation is started, the whole context is sent to the LLM. That allows you to ask follow-up questions with

```lua
:Np chat
```

and once the window is closed, you start with a fresh conversation.

You can select a model from a list of all installed models with

```lua
require('nopilot').select_model()
```

## Custom Prompts

All prompts are defined in `require('nopilot').prompts`, you can enhance or modify them.

Example:
```lua
require('nopilot').prompts['complete'] = {
  prompt = "Complete the following code. Only ouput the result in format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
  replace = false,
  options = {
    temperature = 0.1
  }
}
```

You can use the following properties per prompt:

- `prompt`: (string | function) Prompt either as a string or a function which should return a string. The result can use the following placeholders:
   - `$text`: Visually selected text
   - `$filetype`: Filetype of the buffer (e.g. `javascript`)
   - `$input`: Additional user input
   - `$register`: Value of the unnamed register (yanked text)
- `replace`: `true` if the selected text shall be replaced with the generated output
- `extract`: Regular expression used to extract the generated result
- `model`: The model to use, e.g. `zephyr`, default: `mistral`
