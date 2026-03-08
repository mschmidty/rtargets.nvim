# rtargets.nvim

Helpers for workging with the targets pipelines in neovim.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'mschmidty/rtargets.nvim',
  ft = { "r", "rmd", "quarto" },
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'mschmidty/rtargets.nvim',
  config = function()
    require('rtargets').setup({})
  end
}
```

## Features

Keymaps for common tasks:

- Run the current target under the cursor with `<LocalLeader>tm`
- Make the entire pipeline with `<LocalLeader>m`
- Load everything with `<LocalLeader>le`
- Load target under the cursor with `<LocalLeader>ll`
- Read target under the cursor with `<LocalLeader>tr`
- Take target function name under cursor, create a new file in `R/` with that name, and open it with `<LocalLeader>tw`. A function with the current arguments in the targets function will be written to the new file.
- Go to target function under cursor from the `_targets.R` file in the `R/` folder with `<LocalLeader>tf`.
- Open the `_targets.R` file in the root of the project with `<leader>tt`.

_Note: Most default keymaps use `<LocalLeader>`, while opening the targets file uses `<leader>`._

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
