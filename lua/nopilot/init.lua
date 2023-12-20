local prompts = require("nopilot.prompts")
local M = {
    backends = {
        ollama = require("nopilot.ollama"),
--        exllama = require("nopilot.exllama"),
        openai = require("nopilot.openai"),
    },
    options = {
        backend = "openai"  -- Default backend
    },
    session = {}
}

local curr_buffer = nil
local original_buffer = nil
local start_pos = nil
local end_pos = nil

local function trim_table(tbl)
    local function is_whitespace(str) return str:match("^%s*$") ~= nil end

    while #tbl > 0 and (tbl[1] == "" or is_whitespace(tbl[1])) do
        table.remove(tbl, 1)
    end

    while #tbl > 0 and (tbl[#tbl] == "" or is_whitespace(tbl[#tbl])) do
        table.remove(tbl, #tbl)
    end

    return tbl
end

local backend_defaults = {
    ollama = {
        host = "localhost",
        port = 11434,
        model = "mistral",
        -- Other default config options for ollama
    },
    openai = {
        host = "api.openai.com",
        model = "gpt-3.5-turbo",
        -- Other default config options for OpenAI
    }
}

local default_options = {
    debug = false,
    show_prompt = false,
    show_model = false,
    json_response = true,
    display_mode = "float",
    no_auto_close = false,
}

for k, v in pairs(default_options) do M[k] = v end

function M.setup(opts)
    opts = opts or {}

    -- Apply top-level user options
    for k, v in pairs(opts) do
        M[k] = v
    end

    -- Determine the backend name
    local backend_name = opts.backend.name or M.options.backend  -- This is a string

    -- Check if the backend name is valid and get the default configuration
    local default_config = backend_defaults[backend_name]
    if not default_config then
        error("Unknown backend: " .. backend_name)
    end

    -- If user provided a backend configuration, merge it with the defaults
    local backend_config
    if opts.backend.config then
        backend_config = vim.tbl_deep_extend("force", default_config, opts.backend.config)
    else
        backend_config = default_config
    end

    -- Initialize the selected backend with the merged configuration
    if M.backends[backend_name] then
        M.backend = M.backends[backend_name].new(backend_config)
    else
        error("Unknown backend: " .. backend_name)
    end
end


local function get_window_options()
    local width = math.floor(vim.o.columns * 0.9) -- 90% of the current editor's width
    local height = math.floor(vim.o.lines * 0.9)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local cursor = vim.api.nvim_win_get_cursor(0)
    local new_win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    local middle_row = win_height / 2

    local new_win_height = math.floor(win_height / 2)
    local new_win_row
    if cursor[1] <= middle_row then
        new_win_row = 5
    else
        new_win_row = -5 - new_win_height
    end

    return {
        relative = "cursor",
        width = new_win_width,
        height = new_win_height,
        row = new_win_row,
        col = 0,
        style = "minimal",
        border = "single"
    }
end

local function add_user_message_to_session(prompt)
    table.insert(M.session, {role = "user", content = prompt})
end

local function add_assistant_message_to_session(response)
    table.insert(M.session, {role = "assistant", content = response})
end

function M.reset_session()
    M.session = {}
end

-- Expose the session for external access.
function M.get_session()
    return M.session
end

-- Expose a method to serialize the session to JSON.
function M.session_to_json()
    return vim.fn.json_encode(M.session)
end

local function write_to_buffer(lines)
    if not M.result_buffer or not vim.api.nvim_buf_is_valid(M.result_buffer) then
        return
    end

    local all_lines = vim.api.nvim_buf_get_lines(M.result_buffer, 0, -1, false)

    local last_row = #all_lines
    local last_row_content = all_lines[last_row]
    local last_col = string.len(last_row_content)

    local text = table.concat(lines or {}, "\n")

    vim.api.nvim_buf_set_option(M.result_buffer, "modifiable", true)
    vim.api.nvim_buf_set_text(M.result_buffer, last_row - 1, last_col,
                              last_row - 1, last_col, vim.split(text, "\n"))
    vim.api.nvim_buf_set_option(M.result_buffer, "modifiable", false)
end

local function create_window(opts)
    if M.display_mode == "float" then
        if M.result_buffer then
            vim.api.nvim_buf_delete(M.result_buffer, {force = true})
        end
        local win_opts = vim.tbl_deep_extend("force", get_window_options(),
                                             opts.win_config)
        M.result_buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(M.result_buffer, "filetype", "markdown")

        M.float_win = vim.api.nvim_open_win(M.result_buffer, true, win_opts)
    else
        vim.cmd("vnew nopilot.nvim")
        M.result_buffer = vim.fn.bufnr("%")
        M.float_win = vim.fn.win_getid()
        vim.api.nvim_buf_set_option(M.result_buffer, "filetype", "markdown")
        vim.api.nvim_buf_set_option(M.result_buffer, "buftype", "nofile")
        vim.api.nvim_win_set_option(M.float_win, "wrap", true)
    end
end

local function reset()
    M.result_buffer = nil
    M.float_win = nil
    M.result_string = ""
    M.context = nil
    M.session = {}
end


M.exec = function(options)
    local opts = vim.tbl_deep_extend("force", M, options)
    local has_output = false

    if type(M.backend.init) == 'function' then M.backend.init() end

    curr_buffer = vim.api.nvim_get_current_buf()
    if M.float_win == nil then
        original_buffer = vim.api.nvim_get_current_buf()
    end
    -- vim.notify("Current buffer ID: " .. curr_buffer .. " Original: " .. original_buffer, vim.log.levels.INFO)

    local mode = opts.mode or vim.fn.mode()
    if mode == "v" or mode == "V" then
        start_pos = vim.fn.getpos("'<")
        end_pos = vim.fn.getpos("'>")
        end_pos[3] = vim.fn.col("'>") -- in case of `V`, it would be maxcol instead
    else
        local cursor = vim.fn.getpos(".")
        start_pos = cursor
        end_pos = start_pos
    end

    local content = table.concat(vim.api.nvim_buf_get_text(curr_buffer,
                                                           start_pos[2] - 1,
                                                           start_pos[3] - 1,
                                                           end_pos[2] - 1,
                                                           end_pos[3] - 1, {}),
                                 "\n")

    local function substitute_placeholders(input)
        if not input then return end
        local text = input
        if string.find(text, "%$user") then
            local answer = vim.fn.input("Prompt: ")
            text = string.gsub(text, "%$user", answer)
        end

        if string.find(text, "%$register") then
            local register = vim.fn.getreg('"')
            if not register or register:match("^%s*$") then
                error("Prompt uses $register but yank register is empty")
            end

            text = string.gsub(text, "%$register", register)
        end

        content = string.gsub(content, "%%", "%%%%")
        text = string.gsub(text, "%$visual", content)
        text = string.gsub(text, "%$filetype", vim.bo.filetype)
        return text
    end

    -- prompt formatting
    local prompt = opts.prompt
    if type(prompt) == "function" then
        prompt = prompt({content = content, filetype = vim.bo.filetype})
    end

    prompt = substitute_placeholders(prompt)
    local extractor = substitute_placeholders(opts.extract)

    prompt = string.gsub(prompt, "%%", "%%%%")

    -- Add the formatted user message to the session.
    if M.backend.use_messages then
        add_user_message_to_session(prompt)
    end

    M.result_string = ""
    local cmd = ""
    if M.backend.use_messages then
        cmd = M.backend:build_cmd(M.session, opts)
    else
        cmd = M.backend:build_cmd(prompt, M.context, opts)
    end

    if M.context ~= nil or M.session then write_to_buffer({"", "", "---", ""}) end

    local partial_data = ""
    if opts.debug then print(cmd) end

    if M.result_buffer == nil or M.float_win == nil or
        not vim.api.nvim_win_is_valid(M.float_win) then
        create_window(opts)
        if opts.show_model then
            write_to_buffer({"# Chat with " .. opts.model, ""})
        end
    end

    -- This function will be called when job finishes to process the entire response
    local function process_full_assistant_response(job_id, has_output)
        local response_text = M.result_string
        if response_text and response_text:match("%S") then
            local last_response = M.session[#M.session]

            -- Trim whitespace from both strings to avoid false negatives on this check
            local trimmed_last_content = last_response.content and string.match(last_response.content, "^%s*(.-)%s*$") or ""
            local trimmed_response_text = string.match(response_text, "^%s*(.-)%s*$")

            -- Check if the last assistant message is a prefix of the full message
            if last_response and last_response.role == "assistant" and
                string.sub(trimmed_response_text, 1, #trimmed_last_content) == trimmed_last_content then
                last_response.content = response_text  -- Update only if necessary
            else
                if M.backend.use_messages then
                    add_assistant_message_to_session(response_text)  -- Add if no match
                end
            end
        end
    end

    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data, _)
            if not M.float_win or not vim.api.nvim_win_is_valid(M.float_win) then
                if job_id then vim.fn.jobstop(job_id) end
                if M.result_buffer then
                    vim.api.nvim_buf_delete(M.result_buffer, {force = true})
                end
                reset()
                return
            end

            -- Use parse_data() to handle the incoming data
            -- write to buffer
            local partial_text, context, is_complete = M.backend:parse_data(data, {json_response = opts.json_response})
            if partial_text then
                -- Check if partial_text contains non-whitespace characters
                if partial_text:match("%S") then
                    has_output = true
                end
                M.result_string = M.result_string .. partial_text
                write_to_buffer({partial_text})
            end

            -- if not using messages, then we provide as context
            if context ~= nil and not M.backend.use_messages then
                M.context = context
            end

            -- if is_complete then
            --     write_to_buffer({"", "===== COMPLETE ====", ""})
            -- end
        end,
        on_stderr = function(_, data, _)
            -- Check if the floating window is valid and stop the job if it's not
            if not M.float_win or not vim.api.nvim_win_is_valid(M.float_win) then
                if job_id then vim.fn.jobstop(job_id) end
                return
            end

            -- Check for data and write error messages to the buffer
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" then
                        has_output = true  -- Mark that we have received output
                        write_to_buffer({"Error: " .. line})
                    end
                end
            end
        end,
        on_exit = function(job_id, exit_code)
            if exit_code ~= 0 then
                write_to_buffer({"Command failed with exit code: " .. exit_code})
            elseif not has_output then
                write_to_buffer({"No output received from the model."})
            else
            --if exit_code == 0 then  -- Check that the job completed successfully
                -- Process the full assistant response before any text replacement
                if M.backend.use_messages then
                    process_full_assistant_response(job_id)
                end

                -- Continue with the text replacement and buffer management
                if opts.replace and M.result_buffer then
                    local lines = {}

                    if extractor then
                        local extracted = M.result_string:match(extractor)
                        if not extracted then
                            if not opts.no_auto_close then
                                -- Close the floating window if it's valid
                                if M.float_win and vim.api.nvim_win_is_valid(M.float_win) then
                                    vim.api.nvim_win_hide(M.float_win)
                                end

                                -- Ensure that the buffer ID is valid before attempting to delete
                                if M.result_buffer and vim.api.nvim_buf_is_valid(M.result_buffer) then
                                    vim.api.nvim_buf_delete(M.result_buffer, {force = true})
                                else
                                    print("Error: Invalid buffer ID for deletion.")
                                end
                                reset()
                            end
                            return
                        end
                        lines = vim.split(extracted, "\n", true)
                    else
                        lines = vim.split(M.result_string, "\n", true)
                    end
                    lines = trim_table(lines)
                    vim.api.nvim_buf_set_text(curr_buffer, start_pos[2] - 1,
                                              start_pos[3] - 1, end_pos[2] - 1,
                                              end_pos[3] - 1, lines)
                    if not opts.no_auto_close then
                        -- Close the floating window if it's valid
                        if M.float_win and vim.api.nvim_win_is_valid(M.float_win) then
                            vim.api.nvim_win_hide(M.float_win)
                        end

                        -- Ensure that the buffer ID is valid before attempting to delete
                        if M.result_buffer and vim.api.nvim_buf_is_valid(M.result_buffer) then
                            vim.api.nvim_buf_delete(M.result_buffer, {force = true})
                        else
                            print("Error: Invalid buffer ID for deletion.")
                        end
                        reset()
                    end
                end
            end
            M.result_string = ""
        end
    })

    local group = vim.api.nvim_create_augroup("nopilot", {clear = true})
    vim.api.nvim_create_autocmd('WinClosed', {
        buffer = M.result_buffer,
        group = group,
        callback = function()
            if job_id then vim.fn.jobstop(job_id) end
            if M.result_buffer then
                vim.api.nvim_buf_delete(M.result_buffer, {force = true})
            end
            reset()
        end
    })

    if opts.show_prompt then
        local lines = vim.split(prompt, "\n")
        local short_prompt = {}
        for i = 1, #lines do
            lines[i] = "> " .. lines[i]
            table.insert(short_prompt, lines[i])
            if i >= 3 then
                if #lines > i then
                    table.insert(short_prompt, "...")
                end
                break
            end
        end
        local heading = "#"
        if M.show_model then heading = "##" end
        write_to_buffer({
            heading .. " Prompt:", "", table.concat(short_prompt, "\n"), "",
            "---", ""
        })
    end

    -- Determine which buffer to use for the key mappings
    if M.result_buffer and vim.api.nvim_buf_is_valid(M.result_buffer) then
        -- Function that captures text from a visual selection in the current buffer
        -- This function should be invoked before the result buffer is closed
        local function get_visual_selection(bufnr)
            local start_mark = vim.api.nvim_buf_get_mark(bufnr, '<')
            local end_mark = vim.api.nvim_buf_get_mark(bufnr, '>')
            local text = vim.api.nvim_buf_get_lines(bufnr, start_mark[1] - 1, end_mark[1], false)
            return table.concat(text, vim.api.nvim_get_option('eol') and "\n" or "")
        end

        -- Replace the original selection with the given text
        local function replace_original_selection(text)
            if not vim.api.nvim_buf_is_valid(original_buffer) or
               not vim.api.nvim_buf_get_option(original_buffer, 'modifiable') then
                print("Error: Buffer is not valid or not modifiable.")
                return
            end
            -- Ensure that 'start_pos' and 'end_pos' are correctly set to the original visual selection in the 'curr_buffer'
            local trimmed_lines = vim.split(text, "\n", true)
            vim.api.nvim_buf_set_text(original_buffer, start_pos[2] - 1, start_pos[3]-1, end_pos[2] - 1, end_pos[3] - 1, trimmed_lines)
            -- vim.api.nvim_set_lines(curr_buffer, start_pos[2] - 1, end_pos[2], trimmed_lines)
        end

        local function close_floating_windows()
            if M.float_win and vim.api.nvim_win_is_valid(M.float_win) then
                vim.api.nvim_win_close(M.float_win, true)
            end
        end

        local function delete_result_buffer()
            if M.result_buffer and vim.api.nvim_buf_is_valid(M.result_buffer) then
                vim.api.nvim_buf_delete(M.result_buffer, {force = true})
            end
        end

        -- Keymapping for 'Enter' in visual mode
        -- The keymap callback function is set to normal mode ('n') since it will be used in the 'commands' mode
        vim.keymap.set("x", "<CR>", function()
            -- Capture the visual block from the result buffer before closing it, ensure correct buffer is active and visual mode is initiated.
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
            vim.api.nvim_set_current_buf(M.result_buffer)
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gv", true, false, true), 'x', false)
            M.result_string = get_visual_selection(M.result_buffer)
            -- Replace the original text with the captured content
            replace_original_selection(M.result_string)
            -- Close the floating window and instructions window
            close_floating_windows()
            -- Delete the result buffer
            delete_result_buffer()

            -- Clear the plugin state and cleanup
            reset()
        end, {buffer = M.result_buffer, silent = true})

        -- Function to open visual selection in a new tab
        local function open_in_new_tab()
            -- Escape from visual mode
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
            -- Make the result buffer the current buffer
            vim.api.nvim_set_current_buf(M.result_buffer)
            -- Re-select the previously visual block
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gv", true, false, true), 'x', false)
            -- Capture the visual block
            M.result_string = get_visual_selection(M.result_buffer)
            -- Open a new tab
            vim.api.nvim_command("tabnew")
            -- Paste the captured content into the new tab
            local new_buffer = vim.api.nvim_get_current_buf()
            vim.api.nvim_buf_set_lines(new_buffer, 0, -1, false, vim.split(M.result_string, "\n"))
            -- Optionally set the buffer to unmodified state
            vim.api.nvim_buf_set_option(new_buffer, 'modified', false)
            -- Re-apply syntax highlighting, filetype, etc. if needed
            -- e.g. vim.api.nvim_buf_set_option(new_buffer, 'filetype', '...')

            -- Close the floating window and instructions window
            close_floating_windows()
            -- Delete the result buffer
            delete_result_buffer()

            -- Clear the plugin state and cleanup
            reset()
        end

        -- Keymapping for 'Shift + Enter' in visual mode
        vim.keymap.set("x", "t", open_in_new_tab, {buffer = M.result_buffer, silent = true})

        vim.keymap.set("n", "<esc>", function()
            close_floating_windows()
            delete_result_buffer()
            reset()  -- Assuming reset() is a function that clears the plugin state
        end, {buffer = M.result_buffer, silent = true})
    end
end

M.win_config = {}

M.prompts = prompts

-- Function to determine inputs required by the prompt
local function determineInputs(promptText)
    local inputs = {}
    if string.find(promptText, "%$user") then
        table.insert(inputs, "u")
    end
    if string.find(promptText, "%$visual") then
        table.insert(inputs, "v")
    end
    return table.concat(inputs, ", ")
end

-- Function to create display text for menu items
local function createDisplayText(promptKey, promptText)
    local inputs = determineInputs(promptText)
    if inputs ~= "" then
        return promptKey .. " [" .. inputs .. "]"
    else
        return promptKey
    end
end

-- Function to select a prompt
function select_prompt(cb)
    local menuItems = {}
    for key, value in pairs(M.prompts) do
        local item = {
            name = key,
            displayText = createDisplayText(key, value.prompt)
        }
        table.insert(menuItems, item)
    end

    table.sort(menuItems, function(a, b) return a.displayText < b.displayText end)
    local displayTexts = vim.tbl_map(function(item) return item.displayText end, menuItems)

    vim.ui.select(displayTexts, {
        prompt = "Select a prompt:",
        format_item = function(item) return item end
    }, function(choice, idx)
        if not choice then return end
        local selectedItem = menuItems[idx]
        if selectedItem then
            cb(selectedItem.name)
        end
    end)
end

-- User command implementation
vim.api.nvim_create_user_command("No", function(arg)
    local mode = arg.range == 0 and "n" or "v"
    if arg.args ~= "" then
        local prompt = M.prompts[arg.args]
        if not prompt then
            print("Invalid prompt '" .. arg.args .. "'")
            return
        end
        local p = vim.tbl_deep_extend("force", {mode = mode}, prompt)
        return M.exec(p)
    end
    select_prompt(function(itemName)
        if not itemName then return end
        local p = vim.tbl_deep_extend("force", {mode = mode}, M.prompts[itemName])
        M.exec(p)
    end)
end, {
    range = true,
    nargs = "?",
    complete = function(ArgLead, CmdLine, CursorPos)
        local promptKeys = {}
        for key, _ in pairs(M.prompts) do
            if key:lower():match("^" .. ArgLead:lower()) then
                table.insert(promptKeys, key)
            end
        end
        table.sort(promptKeys)
        return promptKeys
    end
})

-- This function allows you to select a model from a list
M.select_model = function()
    -- List all available models
    local models = M.backend:list_models()

    -- Use vim's built-in UI selection function
    vim.ui.select(models, {prompt = "Model:"}, function(selectedModel, selectedIndex)
        if selectedModel ~= nil then
            print(" Model set to " .. selectedModel)

            -- Attempt to change the model and handle any potential errors
            local success, errorMessage = pcall(function()
                M.backend.model = selectedModel
            end)

            if not success then
                print(" An error occurred: " .. errorMessage)
            end
        end
    end)
end

-- Define a new user command to select a model from the list
vim.api.nvim_create_user_command('SelectModel', function()
    M.select_model();
end, { nargs = 0 })

M.set_temperature = function(temperature)
    assert(type(temperature) == "number" and temperature >= 0 and temperature <= 2, "Temperature must be a number between 0 and 2")
    M.options.temperature = temperature
    vim.notify("Temperature set to " .. temperature)
end

vim.api.nvim_create_user_command('SetTemperature', function(args)
    local arg_list = vim.split(args.args, " ")
    local temperature = tonumber(arg_list[1])
    if temperature then
        M.set_temperature(temperature)
    else
        vim.notify("Invalid input: " .. arg_list[1], vim.log.levels.ERROR)
    end
end, { nargs = 1 })

function M.display_backend_config()
    if M.backend then
        local config_str = vim.inspect(M.backend)
        print("Current Backend Configuration:\n" .. config_str)
    else
        print("No backend configuration available.")
    end
end

vim.api.nvim_create_user_command('DisplayBackendConfig', M.display_backend_config, {})


return M
