-- openai.lua
local openai = {}

function openai.new(config)
    config = config or {}
    -- Define configuration settings for model
    -- Use these in plugin config to change settings
    -- host/port/model for openai compatible models
    local self = {
        host = config.host or "api.openai.com",
        port = config.port or "",
        api = config.api or "/v1/chat/completions",
        model = config.model or "gpt-3.5-turbo",
        headers = config.headers or {  -- List of Headers
            ["Content-Type"] = "application/json",
            ["Authorization"] = string.format("Bearer %s", os.getenv("OPENAI_API_KEY") or ""),
        },
        use_messages = true,
        partial_data = "",
    }

    function self:list_models()
        return {
            "gpt-3.5-turbo",
            "gpt-4",
            "gpt-4-turbo",
        }
    end

    function self:build_cmd(messages, opts)
        opts = opts or {}
        local url = "https://" .. self.host .. (self.port and self.port ~= "" and ":" .. self.port or "") .. self.api
        local cmd = 'curl ' .. url .. ' '

        for key, value in pairs(self.headers) do
            cmd = cmd .. '-H "' .. key .. ': ' .. value .. '" '
        end

        local body = {
            model = self.model,
            messages = messages,
            stream = opts.stream or true
        }

        for _, param in ipairs({"suffix", "max_tokens", "temperature", "top_p", "n", "stop", "presence_penalty", "frequency_penalty", "logit_bias"}) do
            if opts.options[param] ~= nil then
                body[param] = opts.options[param]
            end
        end

        local json = vim.fn.json_encode(body)
        json = vim.fn.shellescape(json)
        cmd = cmd .. '-d ' .. json

        return cmd
    end

    function self:parse_data(data, opts)
        local partial_text = ""
        local is_complete = false
        local context = nil

        local buffer = self.partial_data  -- Use buffer to accumulate JSON data
        for _, line in ipairs(data) do
            -- check for done string
            if line == "data: [DONE]" then
                buffer = ""
                is_complete = true
            else
                -- Remove "data: " prefix and append the line to the buffer
                local json_str = line:gsub("^data: ", "")
                buffer = buffer .. json_str


                local success, json = pcall(vim.fn.json_decode, buffer)
                if success and type(json) == "table" and json.choices and json.choices[1] and json.choices[1].delta then
                    local delta = json.choices[1].delta
                    if delta.content then
                        partial_text = partial_text .. delta.content
                    end

                    buffer = ""  -- Reset the buffer after processing a complete JSON chunk

                    -- Check for the completion condition based on 'finish_reason'
                    if json.choices[1].finish_reason == "stop" then
                        is_complete = true
                    end

                    -- Update context if it exists
                    if json.context ~= nil then
                        context = json.context
                    end
                end
            end
        end

        -- Update partial_data with the remaining buffer content
        self.partial_data = buffer

        return partial_text, context, is_complete
    end

    return self
end

return openai

