---@class GitlabDuo.Adapter: CodeCompanion.Adapter
return {
    name = "gitlab_duo",
    formatted_name = "Gitlab Duo",
    roles = {
        llm = "assistant",
        user = "user",
    },
    opts = {
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
        -- Gitlab Duo currently has a maximum context length of 1000
        maximum_context_length = 1000,
    },
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer ${api_key}",
    },
    handlers = {
        form_messages = function(self, messages)
            -- messages must be shorter than 1000 characters.
            -- This issues with the default system_prompt.
            local merged_content = "";
            for _, message in ipairs(messages) do
                merged_content = merged_content .. message.content
            end
            vim.print(merged_content)
            local merged_content_truncated = string.sub(merged_content, 1, self.maximum_context_length)
            vim.print(merged_content_truncated)
            return { content = merged_content_truncated }
        end,
        chat_output = function(self, data, tools)
            local ok, body = pcall(vim.json.decode, data.body)
            if not ok then
                return {
                    status = "error",
                    output = "Could not parse JSON response",
                }
            end
            if data and data.status >= 400 then
                return {
                    status = "error",
                    output = body.error,
                }
            end
            return {
                status = "success",
                output = {
                    role = "assistant",
                    content = body,
                }
            }
        end,
        inline_output = function(self, data, context)
            local ok, body = pcall(vim.json.decode, data.body)
            if not ok then
                return {
                    status = "error",
                    output = "Could not parse JSON response",
                }
            end
            if data and data.status >= 400 then
                return {
                    status = "error",
                    output = body.error,
                }
            end
            return {
                status = "success",
                output = {
                    role = "assistant",
                    content = body,
                }
            }
        end,
    },
    schema = {
        model = {
            default = "gitlab_duo",
        },
    },
}
