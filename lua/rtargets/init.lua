local M = {}

M.config = {}

-- Attach function: sets up keymaps for a given buffer
function M.attach(bufnr)
  -- Safely check if 'R' module (R.nvim) is available
  local r_ok, _ = pcall(require, "r")
  if not r_ok then
    -- If R.nvim isn't found, we notify the user.
    vim.notify("rtargets.nvim: R.nvim (module 'r') not found. Keymaps not attached.", vim.log.levels.WARN)
    return
  end

  local opts = { buffer = bufnr, silent = true }

  -- Helper for setting keymaps
  local function map(keys, command, description)
    local specific_opts = vim.tbl_extend("force", opts, { desc = description })
    vim.keymap.set("n", keys, command, specific_opts)
  end

  -- Targets: Make
  map("<LocalLeader>m", "<Cmd>lua require('r.send').cmd('tar_make()')<CR>", "Targets: Make")

  -- Targets: Load Everything
  map(
    "<LocalLeader>le",
    "<Cmd>lua require('r.send').cmd('targets::tar_load_everything()')<CR>",
    "Targets: Load Everything"
  )

  -- Targets: Interactive Load
  map("<LocalLeader>ll", "<Cmd>lua require('r.run').action('tar_load')<CR>", "Targets: Interactive Load")

  -- Targets: Interactive Make
  map("<LocalLeader>tm", "<Cmd>lua require('r.run').action('tar_make')<CR>", "Targets: Interactive Make")

  -- Targets: Interactive Read
  map("<LocalLeader>tr", "<Cmd>lua require('r.run').action('tar_read')<CR>", "Targets: Interactive Read")

  print("Targets.R keymaps attached.")
end

-- Setup function: initializes the plugin and sets up autocommands
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local group = vim.api.nvim_create_augroup("Rtargets", { clear = true })

  -- Set up autocommand to attach when R-related files are opened
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "r", "rmd", "quarto" },
    callback = function(args)
      M.attach(args.buf)
    end,
    group = group,
  })
end

return M