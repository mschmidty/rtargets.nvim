-- Lightweight Busted-compatible test runner for Neovim headless

local total_tests = 0
local passed_tests = 0
local failed_tests = 0
local current_before_each = nil

local function assert_true(cond, msg)
  if not cond then error(msg or "Expected true, got " .. tostring(cond), 2) end
end

local function assert_false(cond, msg)
  if cond then error(msg or "Expected false, got " .. tostring(cond), 2) end
end

local function assert_equal(expected, actual)
  if expected ~= actual then
    error("Expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual), 2)
  end
end

local function assert_same(expected, actual)
  if vim.inspect(expected) ~= vim.inspect(actual) then
    error("Expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual), 2)
  end
end

local function assert_nil(val)
  if val ~= nil then error("Expected nil, got " .. vim.inspect(val), 2) end
end

local function assert_not_nil(val)
  if val == nil then error("Expected non-nil value", 2) end
end

_G.assert = setmetatable({
  is_true = assert_true,
  is_false = assert_false,
  is_nil = assert_nil,
  is_not_nil = assert_not_nil,
  are = {
    equal = assert_equal,
    same = assert_same,
  },
}, { __index = _G.assert })

_G.before_each = function(fn)
  current_before_each = fn
end

_G.describe = function(name, fn)
  print("\nDescribe: " .. name)
  local prev_before = current_before_each
  fn()
  current_before_each = prev_before
end

_G.it = function(name, fn)
  total_tests = total_tests + 1
  if current_before_each then
    current_before_each()
  end
  local status, err = pcall(fn)
  if status then
    passed_tests = passed_tests + 1
    print("  [PASS] " .. name)
  else
    failed_tests = failed_tests + 1
    print("  [FAIL] " .. name)
    print("         Error: " .. tostring(err))
  end
end

-- Load spec files
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

dofile("spec/rtargets_spec.lua")

print(string.format("\nTest Summary: %d Passed, %d Failed, %d Total", passed_tests, failed_tests, total_tests))
if failed_tests > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qall!")
end
