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
  -- Check if we are inside a tar_read or tar_load call
  if not cursor_before_line:match("tar_read%s*%(") and not cursor_before_line:match("tar_load%s*%(") then
    callback()
    return
  end

  local items = common.get_items()
  callback(items)
end

return source
