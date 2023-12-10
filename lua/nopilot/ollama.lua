-- ollama.lua
local ollama = {}

function ollama.new(config)
    config = config or {}
    local self = {
        host = config.host or "localhost",
        port = config.port or "11434",
        generate = config.path or "/api/generate",
        tags = config.path or "/api/tags",
        model = config.model,
    }

    function self:list_models()
        local url = "http://" .. self.host .. ":" .. self.port .. self.tags
        local cmd = "curl --silent --no-buffer " .. url

        local response = vim.fn.systemlist(cmd)
        local list = vim.fn.json_decode(response)
        local models = {}
        for key, _ in pairs(list.models) do
            table.insert(models, list.models[key].name)
        end
        table.sort(models)
        return models
    end

    function self:build_cmd(prompt, context, opts)
        local url = "http://" .. self.host .. ":" .. self.port .. self.generate
        local cmd = "curl --silent --no-buffer -X POST " .. url .. " -d $body"

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
                prompt = prompt,
                stream = true
            }

            -- Include context if it exists
            if context then
                body.context = context
            end

            -- Initialize an empty table for options
            local options = {}

            -- Loop through optional parameters and include them if they were set in the opts
            local optional_params = {
                "num_keep", "seed", "num_predict", "top_k", "top_p", "tfs_z",
                "typical_p", "repeat_last_n", "temperature", "repeat_penalty",
                "presence_penalty", "frequency_penalty", "mirostat",
                "mirostat_tau", "mirostat_eta", "penalize_newline", "stop",
                "numa", "num_ctx", "num_batch", "num_gqa", "num_gpu", "main_gpu",
                "low_vram", "f16_kv", "logits_all", "vocab_only", "use_mmap",
                "use_mlock", "embedding_only", "rope_frequency_base",
                "rope_frequency_scale", "num_thread"
            }

            for _, param in ipairs(optional_params) do
                if opts.options and opts.options[param] ~= nil then
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

return ollama
