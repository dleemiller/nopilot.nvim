# nopilot.nvim

`nopilot.nvim` is a Neovim plugin designed for integration with language models, enhancing coding and documentation workflows. It's a fork of David-Kunz's `gen.nvim`, enriched with additional features and capabilities. Nopilot currently has backend support for `ollama` and `openai` streaming backends, and aims to add more in the future.

## Getting Started

### Quick Installation

Install `nopilot.nvim` using your favorite plugin manager. For example, with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "dleemiller/nopilot.nvim" }
```

This sets up `nopilot.nvim` with default options, including the `openai` backend.

## Advanced Installation

Customize your setup with specific backend options:

### OpenAI Backend

```lua
{
    "dleemiller/nopilot.nvim",
    opts = {
        backend = {
            name = "openai",
            config = {
                host = "api.openai.com",
                model = "gpt-3.5-turbo",
                temperature = 0.7,
                max_tokens = 150,
                // Other configurations...
            }
        },
        // Other options...
    }
}
```

Note: Set your OpenAI API key in the `OPENAI_API_KEY` environment variable or provide headers with your API key in the configuration.

### Ollama Backend

```lua
{
    "dleemiller/nopilot.nvim",
    opts = {
        backend = {
            name = "ollama",
            config = {
                host = "localhost",
                port = "11434",
                model = "your-model-name",
                // Other configurations...
            }
        },
        // Other options...
    }
}
```

## Features

### User Interface
- Visual highlight provides context into `$visual` parameter of prompts.
- Use `$user` to provide custom prompt instructions.
- Opens LLM responses in a new buffer window. Use `chat` to interact or provide further instruction.
- Visual replacement: simply highlight and hit `enter` in the window to replace your original selections -- or press `t` to open in a new buffer tab.
- `:SelectModel` opens a menu to change the model
- `:SetTemperature 0.5` sets the temperature to 0.5
- `:DisplayBackendConfig` shows the settings in of the model backend

### Backend Configuration

- **OpenAI Backend**: Customize settings like `host`, `port`, `api`, `model`, and `headers`.
- **Ollama Backend**: Configure Ollama backend with parameters like `host`, `port`, and `model`.
- **Model Selection**: Choose from models for both OpenAI and Ollama backends.
- **Coming Soon**: Additional backends and hot-switching

### Request Customization

Customize the AI request for both backends with configurations such as `temperature`, `max_tokens`, and more.

### Data Parsing and Streaming

The plugin handles partial data and streams responses, ensuring efficient and real-time interaction with the AI.

### Contributing

Contributions are welcome. Please feel free to open issues or submit pull requests.

---

This plugin is under active development, and prompts, configurations and user interface are subject to change.
Stay tuned for ongoing developments and updates in `nopilot.nvim`.
