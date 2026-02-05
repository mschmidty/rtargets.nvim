local common = require("rtargets.common")

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return common.is_available()
end

function source:get_trigger_characters()
  return { "(", ",", '"', "'" }
end

function source:get_completions(ctx, callback)
  local cursor_before_line = ctx.line:sub(1, ctx.cursor[2])
  -- Check if we are inside a tar_read or tar_load call
  if not cursor_before_line:match("tar_read%s*%(") and not cursor_before_line:match("tar_load%s*%(") then
    callback({ items = {} })
    return
  end

  local items = common.get_items()
  callback({ items = items })
end

return source
