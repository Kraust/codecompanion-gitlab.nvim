# CodeCompanion Gitlab Duo Adapter

[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-2C2D72?style=flat-square&logo=lua&logoColor=white)](https://www.lua.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A [Gitlab Duo](https://docs.gitlab.com/api/chat/) Adapter for [CodeCompanion.nvim](https://codecompanion.olimorris.dev/)

## 📋 Requirements

- Neovim >= 0.8.0
- [codecompanion.nvim](https://codecompanion.olimorris.dev/)

## 📦 Installation

### `vim.pack.add`

```lua

vim.pack.add({
    "https://github.com/olimorris/codecompanion.nvim",
    "https://github.com/Kraust/codecompanion-gitlab.nvim",
})

```

### Use Gilab Duo as an Adapter for CodeCompanion.nvim

```lua
require("codecompanion").setup({
    opts = {
        language = "English",
        system_prompt = "",
    },
    strategies = {
        chat = {
            adapter = "gitlab_duo",
            roles = {
                llm = function(adapter)
                    return "CodeCompanion (" .. adapter.formatted_name .. ")"
                end,
                user = "Me",
            },
            keymaps = {
                submit = {
                    modes = { n = "<CR>" },
                    description = "Submit",
                    callback = function(chat)
                        chat:submit()
                    end,
                },
            },
        },
        inline = {
            adapter = "gitlab_duo",
        },
    },
    adapters = {
        gitlab_duo = function()
            return require("codecompanion-gitlab.adapters.gitlab_duo")
        end,
    },
})
```

### Environmental Variables

- `GITLAB_API_KEY` - Your Gitlab [Personal Access Token](https://docs.gitlab.com/user/profile/personal_access_tokens/)
- `GITLAB_URL` - The URL to your Gitlab Instance (e.g. `http://gitlab.my.domain:1235/`)
