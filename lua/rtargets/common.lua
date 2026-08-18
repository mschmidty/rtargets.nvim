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

local buf_dir_cache = {}

local function get_buf_dir(bufnr)
  if buf_dir_cache[bufnr] then
    return buf_dir_cache[bufnr]
  end
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local dir
  if buf_name and buf_name ~= "" then
    dir = vim.fn.fnamemodify(buf_name, ":h")
  else
    dir = vim.fn.getcwd()
  end
  dir = normalize_path(dir) or ""
  buf_dir_cache[bufnr] = dir
  return dir
end

function M.clear_cache()
  targets_dir_cache = {}
  items_cache = {}
  buf_dir_cache = {}
end

function M.find_targets_dir(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local start_dir = get_buf_dir(bufnr)

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

local BYTE_OPEN_PAREN = 40  -- '('
local BYTE_CLOSE_PAREN = 41 -- ')'
local BYTE_SEMICOLON = 59   -- ';'

function M.is_target_context(line_prefix)
  if not line_prefix or line_prefix == "" then
    return false
  end

  local len = #line_prefix
  local paren_depth = 0
  local i = len

  -- Fast exit: scan backwards from cursor using byte values (zero allocations)
  while i >= 1 do
    local b = string.byte(line_prefix, i)

    if b == BYTE_CLOSE_PAREN then
      paren_depth = paren_depth + 1
    elseif b == BYTE_OPEN_PAREN then
      if paren_depth > 0 then
        paren_depth = paren_depth - 1
      else
        -- Found an unclosed '(' wrapping the cursor position
        local prefix = line_prefix:sub(1, i - 1)
        local fn_name = prefix:match("([%w_:]+)%s*$")
        if fn_name and (fn_name:match("^tar_") or fn_name:match("^targets::tar_")) then
          return true
        end
        -- Allow wrapper functions inside tar_load / tar_read (e.g. c(...), list(...))
        if fn_name and not (fn_name == "c" or fn_name == "list" or fn_name == "vector" or fn_name == "vars") then
          return false
        end
      end
    elseif b == BYTE_SEMICOLON then
      break
    end

    i = i - 1
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

