local common = require("rtargets.common")
local cmp_source = require("rtargets.cmp")
local blink_source = require("rtargets.blink")
local rtargets = require("rtargets")

describe("rtargets.common", function()
  before_each(function()
    common.clear_cache()
  end)

  describe("is_target_context", function()
    it("should return false when line does not contain tar_", function()
      assert.is_false(common.is_target_context("print('hello')"))
      assert.is_false(common.is_target_context("foo(bar)"))
      assert.is_false(common.is_target_context(""))
    end)

    it("should return true when inside tar_read or tar_load", function()
      assert.is_true(common.is_target_context("tar_read("))
      assert.is_true(common.is_target_context("tar_read( my_target"))
      assert.is_true(common.is_target_context("tar_load("))
      assert.is_true(common.is_target_context("  tar_load(target_1,"))
    end)

    it("should return true for other targets functions and namespaced calls", function()
      assert.is_true(common.is_target_context("tar_read_raw("))
      assert.is_true(common.is_target_context("targets::tar_read("))
      assert.is_true(common.is_target_context("targets::tar_load("))
      assert.is_true(common.is_target_context("tar_meta("))
    end)

    it("should return true when nested inside c(...) inside tar_load", function()
      assert.is_true(common.is_target_context("tar_load(c(target1, tar2"))
    end)

    it("should return false when tar_read parens are already closed", function()
      assert.is_false(common.is_target_context("tar_read(x) + mean(y"))
      assert.is_false(common.is_target_context("tar_read('target_a'); print("))
    end)

    it("should handle string literals correctly", function()
      assert.is_false(common.is_target_context("print('tar_read(')"))
    end)
  end)

  describe("find_targets_dir and is_available", function()
    it("should return false for non-R filetypes", function()
      vim.bo.filetype = "lua"
      assert.is_false(common.is_available())
    end)

    it("should find _targets directory if present and cache it", function()
      local tmp_dir = vim.fn.tempname()
      vim.fn.mkdir(tmp_dir .. "/_targets", "p")

      local test_file = tmp_dir .. "/test.qmd"
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, test_file)
      vim.bo[buf].filetype = "quarto"

      local found = common.find_targets_dir(buf)
      assert.is_not_nil(found)
      assert.is_true(found:match("_targets$") ~= nil)

      -- Check availability
      assert.is_true(common.is_available(buf))

      -- Test cache performance (should return identical cached value)
      local cached = common.find_targets_dir(buf)
      assert.are.equal(found, cached)

      -- Clean up
      vim.fn.delete(tmp_dir, "rf")
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("get_items", function()
    it("should return target objects from _targets/objects", function()
      local tmp_dir = vim.fn.tempname()
      local objects_dir = tmp_dir .. "/_targets/objects"
      vim.fn.mkdir(objects_dir, "p")

      -- Create dummy target object files
      local f1 = io.open(objects_dir .. "/model_fit", "w")
      if f1 then f1:write("data"); f1:close() end
      local f2 = io.open(objects_dir .. "/data_processed", "w")
      if f2 then f2:write("data"); f2:close() end

      local test_file = tmp_dir .. "/analysis.R"
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, test_file)
      vim.bo[buf].filetype = "r"

      local items = common.get_items(buf)
      assert.are.equal(2, #items)

      local labels = {}
      for _, item in ipairs(items) do
        table.insert(labels, item.label)
      end
      table.sort(labels)
      assert.are.same({ "data_processed", "model_fit" }, labels)

      -- Clean up
      vim.fn.delete(tmp_dir, "rf")
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("cmp and blink completion sources", function()
    it("cmp complete should invoke callback with items inside target context", function()
      local tmp_dir = vim.fn.tempname()
      local objects_dir = tmp_dir .. "/_targets/objects"
      vim.fn.mkdir(objects_dir, "p")
      local f = io.open(objects_dir .. "/target1", "w")
      if f then f:write("1"); f:close() end

      local test_file = tmp_dir .. "/doc.qmd"
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, test_file)
      vim.bo[buf].filetype = "quarto"

      local src = cmp_source.new()

      -- Outside context
      local called_outside = false
      src:complete({ context = { cursor_before_line = "some text", bufnr = buf } }, function(items)
        called_outside = true
        assert.is_nil(items)
      end)
      assert.is_true(called_outside)

      -- Inside context
      local called_inside = false
      src:complete({ context = { cursor_before_line = "tar_read(", bufnr = buf } }, function(items)
        called_inside = true
        assert.is_not_nil(items)
        assert.are.equal(1, #items)
        assert.are.equal("target1", items[1].label)
      end)
      assert.is_true(called_inside)

      -- Clean up
      vim.fn.delete(tmp_dir, "rf")
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("blink get_completions should return items inside target context", function()
      local tmp_dir = vim.fn.tempname()
      local objects_dir = tmp_dir .. "/_targets/objects"
      vim.fn.mkdir(objects_dir, "p")
      local f = io.open(objects_dir .. "/target_blink", "w")
      if f then f:write("1"); f:close() end

      local test_file = tmp_dir .. "/doc.qmd"
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, test_file)
      vim.bo[buf].filetype = "quarto"

      local src = blink_source.new()

      -- Inside context
      local called = false
      src:get_completions({ line = "tar_read(tar", cursor = { 1, 11 }, bufnr = buf }, function(response)
        called = true
        assert.is_not_nil(response)
        assert.are.equal(1, #response.items)
        assert.are.equal("target_blink", response.items[1].label)
      end)
      assert.is_true(called)

      -- Clean up
      vim.fn.delete(tmp_dir, "rf")
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)
end)
