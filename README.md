# rtargets.nvim

Helpers for workging with the targets pipelines in neovim.

## Features

Keymaps for common tasks:

- Run the current target under the cursor with `<leader>tm`
- Make the entire pipeline with `<leader>m`
- Load target under the cursor with `<leader>ll`
- Take target function name under cursor, create a new file in `R/` with that name, and open it with `<leader>tw`. A function with the current arguments in the targets function will be written to the new file.
- Go to target function under cursor from the \_targets.R file in the R/ folder with `<leader>tf`.

More to come soon!!

### Fair warning

This was vibe coded for my own personal use and to start to learn lua. Recommendations welcome!
