local common = require("rtargets.common")

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:is_available()
  return common.is_available()
end

function source:get_debug_name()
  return "rtargets"
end

function source:get_trigger_characters()
  return { "(" }
end

function source:complete(params, callback)
  local cursor_before_line = params.context.cursor_before_line
  if not common.is_target_context(cursor_before_line) then
    callback()
    return
  end

  local bufnr = params.context and params.context.bufnr
  local items = common.get_items(bufnr)
  callback(items)
end

return source
