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
            if not data or data == "" then
                return nil
            end
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
            json = json:match("%*%*%* Begin Response%s*\n(.-)\n%s*%*%*%* End Response")
            json = json:gsub("`%s*`%s*`", "```")
            data.body = json
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

            local message = {
                category = "file",
                id = "system",
                content = [[
Your Response Must:
1. Be wrapped in *** Begin Response / *** End Response markers"
2. Must be a serialized JSON-formatted OpenAI Response which has been minifiled before serialization.
3. The text requested by the propmt must be serialized as a string and inserted into the JSON-formatted OpenAI response.
If you're requested to return a JSON object:
1. The JSON must be represented as a string represented as %s in the following format:
```json
{
    "id": "chatcmpl-codecompanion-023",
    "object": "chat.completion",
    "created": 1703097716,
    "model": "codecompanion",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "%s"
            }
        }
    ],
    "finish_reason": "stop",
    "usage": {
        "prompt_tokens": 150,
        "completion_tokens": 600,
        "total_tokens": 750
    }
}
```
2. If the content field is not a valid json string because it ends with two double quotes, remove one of them.
]]
            }
            table.insert(messages, 1, message)

            return {
                content = "Follow the messages in additional_context as instructed.",
                additional_context = messages,
            }
        end,
        form_tools = function(self, tools)
            return openai.handlers.form_tools(self, tools)
        end,
        chat_output = function(self, data, tools)
            if not data or data == "" then
                return nil
            end
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
                json = json:match("%*%*%* Begin Response%s*\n(.-)\n%s*%*%*%* End Response")
                json = json:gsub("`%s*`%s*`", "```")
                data.body = json
            end
            return openai.handlers.chat_output(self, data, tools)
        end,
        inline_output = function(self, data, context)
            if not data or data == "" then
                return nil
            end
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
            json = json:match("%*%*%* Begin Response%s*\n(.-)\n%s*%*%*%* End Response")
            json = json:gsub("`%s*`%s*`", "```")
            data.body = json
            return openai.handlers.inline_output(self, data, context)
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
