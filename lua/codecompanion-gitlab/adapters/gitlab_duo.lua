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
            if json then
                json = json:gsub("`%s*`%s*`", "```")
            end
            vim.print(json)
            data.body = json
            return openai.handlers.chat_output(self, data)
        end,
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
            if json then
                json = json:gsub("`%s*`%s*`", "```")
            end
            vim.print(json)

            -- Process tool calls from all choices
            if self.opts.tools and tools then
                -- for _, choice in ipairs(json.choices) do
                --     local delta = self.opts.stream and choice.delta or choice.message
                --
                --     if delta and delta.tool_calls and #delta.tool_calls > 0 then
                --         for i, tool in ipairs(delta.tool_calls) do
                --             local tool_index = tool.index and tonumber(tool.index) or i
                --
                --             -- Some endpoints like Gemini do not set this (why?!)
                --             local id = tool.id
                --             if not id or id == "" then
                --                 id = string.format("call_%s_%s", json.created, i)
                --             end
                --
                --             table.insert(tools, {
                --                 _index = i,
                --                 id = id,
                --                 type = tool.type,
                --                 ["function"] = {
                --                     name = tool["function"]["name"],
                --                     arguments = tool["function"]["arguments"],
                --                 },
                --             })
                --         end
                --     end
                -- end
            end


            -- return {
            --     status = "success",
            --     output = {
            --         role = "assistant",
            --         content = json,
            --     }
            -- }
            --
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
            if json then
                json = json:gsub("`%s*`%s*`", "```")
            end
            vim.print(json)
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
