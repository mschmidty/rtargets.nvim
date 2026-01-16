local M = {}

function M.on_attache(bufnr)
  local r_ok, _ = pcall(require, "R")
  if not r_ok then
    return
  end

  local opts = { buffer = bufnr, silent = true }

  local function map(keys, command, description)
    local specific_opts = vim.tbl_extend("force", opts, { desc = description })
    vim.keymap.set("n", keys, command, specific_opts)
  end

  -- Run tar_make()
  map("<LocalLeader>m", "<Cmd>lua require('r.send').cmd('tar_make()')<CR>", "Targets: Make")

  -- Load everything
  map(
    "<LocalLeader>le",
    "<Cmd>lua require('r.send').cmd('targets::tar_load_everything()')<CR>",
    "Targets: Load Everything"
  )

  -- Action: tar_load (usually triggers an input or prompt in R.nvim)
  map("<LocalLeader>ll", "<Cmd>lua require('r.run').action('tar_load')<CR>", "Targets: Interactive Load")

  -- Action: tar_make
  map("<LocalLeader>tm", "<Cmd>lua require('r.run').action('tar_make')<CR>", "Targets: Interactive Make")

  -- Action: tar_read
  map("<LocalLeader>tr", "<Cmd>lua require('r.run').action('tar_read')<CR>", "Targets: Interactive Read")

  print("Targets.R keymaps attached.")
end

function M.on_attach(bufnr)
  M.config = opts or {}

  local group = vim.api.nvim_create_augroup("Rtargets", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "r", "rmd", "quarto" },
    callback = function(args)
      M.on_attache(args.buf)
    end,
    group = group,
  })
end

return M
