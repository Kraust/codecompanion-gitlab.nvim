local openai = require("codecompanion.adapters.openai")

---@class GitlabDuo.Adapter: CodeCompanion.Adapter
return {
    name = "gitlab_duo",
    formatted_name = "Gitlab Duo",
    roles = {
        llm = "assistant",
        user = "user",
        tool = "tool",
    },
    opts = {
        tools = true,
    },
    features = {
        text = true,
        tokens = false,
    },
    url = "${url}${chat_url}",
    env = {
        api_key = "GITLAB_API_KEY",
        url = "GITLAB_URL",
        chat_url = "/api/v4/chat/completions",
    },
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer ${api_key}",
    },
    handlers = {
        form_messages = function(self, messages)
            -- messages must be shorter than 1000 characters.
            -- This issues with the default system_prompt.
            messages = vim
                .iter(messages)
                :map(function(message)
                    return {
                        category = "file",
                        id = message.role,
                        content = message.content,
                    }
                end)
                :totable()

            local message = {
                category = "file",
                id = "user",
                content = [[
You are an OpenAI Compatible API and should conform to the OpenAI API Spec.
    - The response should be in raw JSON format.
    - The fields in the response should be accurate to the current model being used.
    - Do NOT respond with anything other than OpenAI compatible responses.
]]
            }
            table.insert(messages, 1, message)

            return {
                content = "Follow the messages in additional_context as instructed.",
                additional_context = messages,
            }
        end,
        form_tools = function(self, tools)
            if not self.opts.tools or not tools then
                return
            end
            if vim.tbl_count(tools) == 0 then
                return
            end

            local transformed = {}
            for _, tool in pairs(tools) do
                for _, schema in pairs(tool) do
                    table.insert(transformed, schema)
                end
            end

            return { tools = transformed }
        end,
        chat_output = function(self, data, tools)
            local ok, json = pcall(vim.json.decode, data.body)
            if not ok then
                return {
                    status = "error",
                    output = "Could not parse JSON response",
                }
            end
            if data and data.status >= 400 then
                return {
                    status = "error",
                    output = json.error,
                }
            end
            -- JSON needs to have its backticks fixed. The Model reports
            -- that it cannot perform this action.
            json = json:gsub("`%s*`%s*`", "```")
            vim.print(json)
            data.body = json
            return openai.handlers.chat_output(self, data, tools)
        end,
        inline_output = function(self, data, context)
            local ok, json = pcall(vim.json.decode, data.body)
            if not ok then
                return {
                    status = "error",
                    output = "Could not parse JSON response",
                }
            end
            if data and data.status >= 400 then
                return {
                    status = "error",
                    output = json.error,
                }
            end
            -- JSON needs to have its backticks fixed. The Model reports
            -- that it cannot perform this action.
            json = json:gsub("`%s*`%s*`", "```")
            vim.print(json)
            data.body = json
            return openai.handlers.chat_output(self, data, context)
        end,
        tools = {
            format_tool_calls = function(self, tools)
                return openai.handlers.tools.format_tool_calls(self, tools)
            end,
            output_response = function(self, tool_call, output)
                return openai.handlers.tools.output_response(self, tool_call, output)
            end,
        },
    },
    schema = {
        model = {
            default = "gitlab_duo",
        },
    },
}
