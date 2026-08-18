local M = {}

local uv = vim.uv or vim.loop

local targets_dir_cache = {}
local items_cache = {}
local CACHE_TTL_MS = 2000

local function normalize_path(path)
  if not path or path == "" then
    return nil
  end
  path = path:gsub("\\", "/")
  path = path:gsub("/+$", "")
  return path
end

local function is_dir(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

local function search_upwards_for_targets(start_dir)
  local current = normalize_path(start_dir)
  if not current or current == "" then
    return nil
  end

  while current and current ~= "" do
    local candidate = current .. "/_targets"
    if is_dir(candidate) then
      return candidate
    end

    local parent = normalize_path(vim.fn.fnamemodify(current, ":h"))
    if not parent or parent == current then
      break
    end
    current = parent
  end

  return nil
end

function M.clear_cache()
  targets_dir_cache = {}
  items_cache = {}
end

function M.find_targets_dir(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local start_dir
  if buf_name and buf_name ~= "" then
    start_dir = vim.fn.fnamemodify(buf_name, ":h")
  else
    start_dir = vim.fn.getcwd()
  end
  start_dir = normalize_path(start_dir) or ""

  local now = uv.now()
  local cached = targets_dir_cache[start_dir]
  if cached and (now - cached.time < CACHE_TTL_MS) then
    return cached.path or nil
  end

  local found = search_upwards_for_targets(start_dir)
  targets_dir_cache[start_dir] = {
    path = found,
    time = now,
  }
  return found
end

function M.is_available(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  if ft ~= "r" and ft ~= "rmd" and ft ~= "quarto" then
    return false
  end

  return M.find_targets_dir(bufnr) ~= nil
end

function M.is_target_context(line_prefix)
  if not line_prefix or line_prefix == "" then
    return false
  end

  -- Fast exit if 'tar_' is not anywhere in the line prefix
  if not line_prefix:find("tar_") then
    return false
  end

  local stack = {}
  local len = #line_prefix
  local in_string = nil
  local i = 1

  while i <= len do
    local char = line_prefix:sub(i, i)
    if in_string then
      if char == in_string and line_prefix:sub(i - 1, i - 1) ~= "\\" then
        in_string = nil
      end
    elseif char == '"' or char == "'" or char == "`" then
      in_string = char
    elseif char == "(" then
      table.insert(stack, i)
    elseif char == ")" then
      if #stack > 0 then
        table.remove(stack)
      end
    end
    i = i + 1
  end

  for s = #stack, 1, -1 do
    local open_pos = stack[s]
    local prefix_before_open = line_prefix:sub(1, open_pos - 1)
    local fn_name = prefix_before_open:match("([%w_:]+)%s*$")
    if fn_name and (fn_name:match("^tar_") or fn_name:match("^targets::tar_")) then
      return true
    end
  end

  return false
end

function M.get_items(bufnr)
  local targets_dir = M.find_targets_dir(bufnr)
  if not targets_dir then
    return {}
  end

  local objects_path = targets_dir .. "/objects"
  local stat = uv.fs_stat(objects_path)
  if not stat or stat.type ~= "directory" then
    return {}
  end

  local now = uv.now()
  local mtime = stat.mtime.sec
  local cached = items_cache[objects_path]

  if cached and cached.mtime == mtime and (now - cached.time < CACHE_TTL_MS) then
    return cached.items
  end

  local handle = uv.fs_scandir(objects_path)
  local items = {}
  if handle then
    while true do
      local name = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if not name:match("^%.") then
        table.insert(items, {
          label = name,
          kind = 6, -- CompletionItemKind.Variable
          detail = "Target",
        })
      end
    end
  end

  items_cache[objects_path] = {
    items = items,
    mtime = mtime,
    time = now,
  }

  return items
end

return M

