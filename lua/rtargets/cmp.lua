local source = {}

local function find_targets_dir()
  -- Search upwards for _targets directory
  local targets_dir = vim.fn.finddir("_targets", ".;")
  if targets_dir == "" then
    return nil
  end
  return vim.fn.fnamemodify(targets_dir, ":p"):gsub("/$", "")
end

function source.new()
  return setmetatable({}, { __index = source })
end

function source:is_available()
  -- Only enable for R related filetypes
  local ft = vim.bo.filetype
  if ft ~= "r" and ft ~= "rmd" and ft ~= "quarto" then
    return false
  end
  
  return find_targets_dir() ~= nil
end

function source:get_debug_name()
  return 'rtargets'
end

function source:get_trigger_characters()
  return { '(', ',', '"', "'" }
end

function source:complete(params, callback)
  local cursor_before_line = params.context.cursor_before_line
  -- Check if we are inside a tar_read or tar_load call
  if not cursor_before_line:match("tar_read%s*%(") and not cursor_before_line:match("tar_load%s*%(") then
    callback()
    return
  end

  local targets_dir = find_targets_dir()
  if not targets_dir then
    callback()
    return
  end
  
  local objects_path = targets_dir .. "/objects"
  if vim.fn.isdirectory(objects_path) == 0 then
    callback()
    return
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
  
  callback(items)
end

return source