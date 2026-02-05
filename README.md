# rtargets.nvim

Helpers for workging with the targets pipelines in neovim.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'michaelschmidt/rtargets.nvim',
  ft = { "r", "rmd", "quarto" },
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'michaelschmidt/rtargets.nvim',
  config = function()
    require('rtargets').setup({})
  end
}
```

## Features

Keymaps for common tasks:

- Run the current target under the cursor with `<leader>tm`
- Make the entire pipeline with `<leader>m`
- Load target under the cursor with `<leader>ll`
- Take target function name under cursor, create a new file in `R/` with that name, and open it with `<leader>tw`. A function with the current arguments in the targets function will be written to the new file.
- Go to target function under cursor from the \_targets.R file in the R/ folder with `<leader>tf`.

## Completion

`rtargets.nvim` provides a completion source for both `nvim-cmp` and `blink.cmp`.

### nvim-cmp

If you use `nvim-cmp`, the source is automatically registered when the plugin is loaded. You just need to add it to your `cmp` setup:

```lua
require('cmp').setup({
  sources = {
    { name = 'rtargets' },
    -- other sources
  }
})
```

### blink.cmp

If you use `blink.cmp`, you can add `rtargets` as a provider in your configuration:

```lua
require('blink.cmp').setup({
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'rtargets' },
    providers = {
      rtargets = {
        name = 'rtargets',
        module = 'rtargets.blink',
        score_offset = 100,
      },
    },
  },
})
```

## Fair warning

This was vibe coded for my own personal use and to start to learn lua. Recommendations welcome!
