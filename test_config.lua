-- Mock vim global
local recorded_maps = {}
_G.vim = {
  fn = {
    mode = function() return "n" end,
    getcwd = function() return "." end,
    mkdir = function() return 1 end,
  },
  api = {
    nvim_create_augroup = function() end,
    nvim_create_autocmd = function() end,
  },
  notify = function(msg, level) print("NOTIFY:", msg) end,
  keymap = {
    set = function(mode, lhs, rhs, opts) 
      print("Mapped: " .. lhs .. " -> " .. opts.desc)
      recorded_maps[opts.desc] = lhs
    end
  },
  tbl_deep_extend = function(behavior, t1, t2) 
      -- simple shallow merge for this test is not enough for nested maps
      -- implementing a basic deep extend for 'maps'
      if t2.maps then
          for k, v in pairs(t2.maps) do
              t1.maps[k] = v
          end
      end
      return t1
  end,
  tbl_extend = function(behavior, t1, t2) return t2 end, -- dummy
}

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local rtargets = require("rtargets")

-- Test 1: Default config
print("--- Test 1: Defaults ---")
rtargets.setup({})
rtargets.attach(1)

local expected_defaults = {
    ["Targets: Make"] = "<LocalLeader>m",
    ["Targets: Load Everything"] = "<LocalLeader>le",
    ["Targets: Interactive Load"] = "<LocalLeader>ll",
    ["Targets: Interactive Make"] = "<LocalLeader>tm",
    ["Targets: Interactive Read"] = "<LocalLeader>tr",
}

for desc, key in pairs(expected_defaults) do
    if recorded_maps[desc] ~= key then
        print("FAILURE: Expected " .. key .. " for " .. desc .. ", got " .. tostring(recorded_maps[desc]))
    else
        print("PASS: " .. desc)
    end
end

-- Test 2: Custom config
print("\n--- Test 2: Custom Config ---")
recorded_maps = {}
rtargets.setup({
    maps = {
        tar_make = "<Leader>mm", -- Changed
        tar_load = false, -- Disabled
    }
})
rtargets.attach(1)

if recorded_maps["Targets: Make"] == "<Leader>mm" then
    print("PASS: Custom Key applied")
else
    print("FAILURE: Custom Key not applied. Got: " .. tostring(recorded_maps["Targets: Make"]))
end

if recorded_maps["Targets: Interactive Load"] == nil then
    print("PASS: Disabled map skipped")
else
    print("FAILURE: Disabled map was set to " .. tostring(recorded_maps["Targets: Interactive Load"]))
end