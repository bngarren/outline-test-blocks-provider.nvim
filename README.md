# outline-test-blocks-provider.nvim

<div align=center>
	
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.10+-green.svg?style=for-the-badge&logo=neovim&color=%2343743f)](https://neovim.io)
![GitHub Release](https://img.shields.io/github/v/release/bngarren/outline-test-blocks-provider.nvim?style=for-the-badge&logoSize=200&color=%23f3d38a&labelColor=%23061914)

</div>

A simple external provider for [outline.nvim](https://github.com/hedyhli/outline.nvim) that shows your test blocks, e.g., `describe(...)`, `it(...)`, etc calls in the Outline.

🚀 Automatically enabled for the following languages:

- Typescript
- Javascript
- Lua

<img src="./assets/example1.png" />

## Installation

### Using **lazy.nvim**

Modify your outline.nvim lazy spec to include the `outline-test-blocks-provider.nvim` dependency:

```lua
return {
  "hedyhli/outline.nvim",
  lazy = true,
  dependencies = {
    "bngarren/outline-test-blocks-provider.nvim",
  },
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
  },
  opts = {
    -- Add the "test_blocks" provider before "lsp"
    providers = {
      priority = { "test_blocks", "lsp", "coc", "markdown", "norg" },
      -- Configure the test_blocks provider here:
      test_blocks = {
        enable = { describe = true, it = true, pending = false },
        max_depth = 5,
      },
    },
  },
}
```

## Config

>[!NOTE]
>It defaults to activating for any buffer in which it finds one of the enabled test blocks (e.g. `describe`, `it`, etc) within the first 500 lines. You can pass your own `supports_buffer(bufnr)` function to customize it to your liking.

```lua
---@class test_blocks.Config
---
---Which test blocks to enable
---Default: { describe = true, it = true }
---@field enable? table<string, boolean>
---
---Whether to activate test_blocks provider for this buffer
---Default: a buffer with the test blocks in `enable` found within it
---i.e., if `it` or `describe` are found, will use test_blocks
---@field supports_buffer? function(bufnr: integer): boolean
---
---Max number of nested nodes to show in the outline
---Default: 5
---@field max_depth? integer
---
---Attempts to resize the outline sidebar for this provider
---E.g. 40 will be 40%
---Default: uses the global outline.nvim config
---@field sidebar_width? integer

---@type test_blocks.Config
M.defaults = {
	enable = { describe = true, it = true },
	max_depth = 5,
}
```

# Contributing

If you have feature suggestions or ideas, please feel free to open an issue on GitHub!

# Credits

Thanks to [@hedyhli](https://github.com/hedyhli) for an awesome [outline.nvim](https://github.com/hedyhli/outline.nvim) plugin!
