-- Add current directory to runtime path so we can require 'rtargets'
vim.opt.rtp:prepend(".")

print("Attempting to require 'rtargets'...")

-- Try to load the module
local status, result = pcall(require, "rtargets")

if status then
  print("SUCCESS: Module loaded successfully.")
  print("Result type: " .. type(result))
  if type(result) == "table" and result.setup then
    print("SUCCESS: setup function found.")
    -- Try calling setup
    local setup_status, setup_err = pcall(result.setup, {})
    if setup_status then
      print("SUCCESS: setup() called without error.")
    else
      print("ERROR: setup() failed: " .. tostring(setup_err))
    end
  else
    print("WARNING: setup function missing or module is not a table.")
  end
else
  print("CRITICAL ERROR: Failed to load module.")
  print(tostring(result))
end

vim.cmd("q")
