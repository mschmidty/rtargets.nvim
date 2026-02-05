local M = {}

function M.find_targets_dir()
  -- Search upwards for _targets directory
  local targets_dir = vim.fn.finddir("_targets", ".;")
  if targets_dir == "" then
    return nil
  end
  return vim.fn.fnamemodify(targets_dir, ":p"):gsub("/$", "")
end

function M.is_available()
  -- Only enable for R related filetypes
  local ft = vim.bo.filetype
  if ft ~= "r" and ft ~= "rmd" and ft ~= "quarto" then
    return false
  end

  return M.find_targets_dir() ~= nil
end

function M.get_items()
  local targets_dir = M.find_targets_dir()
  if not targets_dir then
    return {}
  end

  local objects_path = targets_dir .. "/objects"
  if vim.fn.isdirectory(objects_path) == 0 then
    return {}
  end

  local files = vim.fn.glob(objects_path .. "/*", true, true)
  local items = {}

  for _, filepath in ipairs(files) do
    local name = vim.fn.fnamemodify(filepath, ":t")
    if not name:match("^%.") then
      table.insert(items, {
        label = name,
        kind = 6, -- CompletionItemKind.Variable
        detail = "Target",
      })
    end
  end

  return items
end

return M
