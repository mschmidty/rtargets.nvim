local M = {}

M.config = {
  maps = {
    tar_make = "<LocalLeader>m",
    tar_load_everything = "<LocalLeader>le",
    tar_load = "<LocalLeader>ll",
    tar_make_interactive = "<LocalLeader>tm",
    tar_read = "<LocalLeader>tr",
    tar_create = "<LocalLeader>tw",
    tar_open = "<LocalLeader>tf",
  },
}

local function get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))

  if ls == 0 or le == 0 then
    return nil
  end

  if ls > le or (ls == le and cs > ce) then
    ls, cs, le, ce = le, ce, ls, cs
  end
  local lines = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
  return table.concat(lines, "")
end

function M.create_file_from_selection()
  local mode = vim.fn.mode()
  local name
  if mode:match("^[vV]") or mode == "\22" then
    name = get_visual_selection()
    -- Exit visual mode after getting the selection
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  else
    -- Normal mode: check for function call
    local save_cursor = vim.fn.getcurpos()
    local word = vim.fn.expand("<cword>")

    -- Check if followed by '('
    vim.cmd("normal! e")
    local col = vim.fn.col(".")
    local line = vim.api.nvim_get_current_line()
    -- Check next char safely
    if col < #line and string.sub(line, col + 1, col + 1) == "(" then
      vim.cmd("normal! l") -- on '('
      local start_pos = vim.fn.getpos(".")
      vim.cmd("normal! %") -- on ')'
      local end_pos = vim.fn.getpos(".")

      -- Extract text between start_pos and end_pos (inclusive)
      local s_row, s_col = start_pos[2] - 1, start_pos[3] - 1
      local e_row, e_col = end_pos[2] - 1, end_pos[3]

      local lines = vim.api.nvim_buf_get_text(0, s_row, s_col, e_row, e_col, {})
      local args_text = table.concat(lines, "\n")

      name = word .. args_text
    else
      name = word
    end
    vim.fn.setpos(".", save_cursor)
  end

  if not name or name == "" then
    vim.notify("No valid target name found in selection or under cursor.", vim.log.levels.ERROR)
    return
  end
  name = name:gsub("[\n\r]", "") -- Remove newlines

  local base_name, args = name:match("^([^%(]+)%((.*)%)")
  if not base_name then
    base_name = name:gsub("%.[Rr]$", "")
    args = ""
  else
    base_name = base_name:gsub("%.[Rr]$", "")
  end

  local project_root = vim.fn.getcwd()
  local r_dir = project_root .. "/R"

  local success = vim.fn.mkdir(r_dir, "p")

  if success == 0 then
    vim.notify("Failed to create R/ directory at " .. r_dir, vim.log.levels.ERROR)
    return
  end

  local filename = base_name .. ".R"
  local file_path = r_dir .. "/" .. filename
  local file = io.open(file_path, "r")

  if file then
    io.close()
    vim.notify("File " .. file_path .. " already exists.", vim.log.levels.WARN)
    vim.cmd("edit " .. file_path)
  else
    file = io.open(file_path, "w")
    if file then
      file:write(base_name .. "<-function(" .. args .. "){}")
      file:close()
      -- vim.notify("Created: R/" .. filename, vim.log.levels.INFO)
      vim.cmd("edit " .. file_path)
    else
      vim.notify("Failed to create file: " .. file_path, vim.log.levels.ERROR)
    end
  end
end

function M.open_target_file()
  local word = vim.fn.expand("<cword>")
  if not word or word == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end

  local project_root = vim.fn.getcwd()
  local r_dir = project_root .. "/R"
  local filename = word .. ".R"
  local file_path = r_dir .. "/" .. filename

  local file = io.open(file_path, "r")
  if file then
    io.close()
    vim.cmd("edit " .. file_path)
  else
    vim.notify("File " .. file_path .. " does not exist.", vim.log.levels.WARN)
  end
end

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
  local function map(keys, command, description, mode)
    mode = mode or "n"
    local specific_opts = vim.tbl_extend("force", opts, { desc = description })
    vim.keymap.set(mode, keys, command, specific_opts)
  end

  -- Targets: Make
  if M.config.maps.tar_make then
    map(M.config.maps.tar_make, "<Cmd>lua require('r.send').cmd('tar_make()')<CR>", "Targets: Make")
  end

  -- Targets: Load Everything
  if M.config.maps.tar_load_everything then
    map(
      M.config.maps.tar_load_everything,
      "<Cmd>lua require('r.send').cmd('targets::tar_load_everything()')<CR>",
      "Targets: Load Everything"
    )
  end

  -- Targets: Interactive Load
  if M.config.maps.tar_load then
    map(M.config.maps.tar_load, "<Cmd>lua require('r.run').action('tar_load')<CR>", "Targets: Interactive Load")
  end

  -- Targets: Interactive Make
  if M.config.maps.tar_make_interactive then
    map(
      M.config.maps.tar_make_interactive,
      "<Cmd>lua require('r.run').action('tar_make')<CR>",
      "Targets: Interactive Make"
    )
  end

  -- Targets: Interactive Read
  if M.config.maps.tar_read then
    map(M.config.maps.tar_read, "<Cmd>lua require('r.run').action('tar_read')<CR>", "Targets: Interactive Read")
  end

  -- Targets: Create File from Selection
  if M.config.maps.tar_create then
    local create_cmd = "<Cmd>lua require('rtargets').create_file_from_selection()<CR>"
    map(M.config.maps.tar_create, create_cmd, "Targets: Create File from Selection", { "n", "x" })
  end

  -- Targets: Open Target File
  if M.config.maps.tar_open then
    map(M.config.maps.tar_open, "<Cmd>lua require('rtargets').open_target_file()<CR>", "Targets: Open Target File")
  end
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
