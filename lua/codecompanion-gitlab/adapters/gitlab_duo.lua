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
        tokens = true,
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
        tokens = function(self, data)
            vim.print(data)
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
            data.body = json
            vim.print(json)
            return openai.handlers.tokens(self, data)
        end,
        form_parameters = function(self, params, messages)
            return openai.handlers.form_parameters(self, params, messages)
        end,
        form_messages = function(self, messages)
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
            vim.print(messages)
            return {
                content = "Follow the messages in additional_context as instructed.",
                additional_context = messages,
            }
        end,
        form_tools = function(self, tools)
            return openai.handlers.form_tools(self, tools)
        end,
        chat_output = function(self, data, tools)
            if self.opts and self.opts.tokens == false then
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
                data.body = json
            end
            return openai.handlers.chat_output(self, data, tools)
        end,
        inline_output = function(self, data, context)
            if self.opts and self.opts.tokens == false then
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
                data.body = json
            end
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
