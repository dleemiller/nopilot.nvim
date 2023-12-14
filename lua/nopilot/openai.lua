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
        local url = "https://" .. self.host
        if self.port and self.port ~= "" then
            url = url .. ":" .. self.port
        end
        url = url .. self.api

        -- Initialize curl command with POST method and URL
        local cmd = 'curl -X POST "' .. url .. '" '

        -- Iterate over headers in self
        for key, value in pairs(self.headers) do
            -- Add each header to the curl command as a separate -H option
            cmd = cmd .. '-H "' .. key .. ': ' .. value .. '" '
        end

        -- Add the data to the curl command
        cmd = cmd .. '-d $body'

        local function is_table_empty(t)
            if t == nil or next(t) == nil then
                return true
            else
                return false
            end
        end

        if string.find(cmd, "%$body") then
            local body = {
                model = self.model,
                messages = messages,
                stream = opts.stream or true
            }

            -- Initialize an empty table for options
            local options = {}

            -- Loop through optional parameters and include them if they were set in the opts
            local optional_params = {
                "model", "prompt", "suffix", "max_tokens", "temperature",
                "top_p", "n", "stream", "stop", "presence_penalty",
                "frequency_penalty", "logit_bias"
            }
            for _, param in ipairs(optional_params) do
                if opts.options[param] ~= nil then
                    options[param] = opts.options[param]
                end
            end

            -- Add options to the body only if options are not empty
            if not is_table_empty(options) then
                body.options = options
            end

            -- Encode to JSON and shell-escape
            local json = vim.fn.json_encode(body)
            json = vim.fn.shellescape(json)
            cmd = string.gsub(cmd, "%$body", json)
        end
        return cmd
    end

    return self
end

return openai

