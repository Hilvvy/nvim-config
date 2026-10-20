-- Pure configuration regression test: no downloads or plugin execution.
local old_has, old_stat = vim.fn.has, vim.uv.fs_stat
local old_lazy = package.loaded.lazy
local old_root, old_portable = vim.env.HILVIM_ROOT, vim.env.HILVIM_PORTABLE
local ok, err = xpcall(function()
  for _, case in ipairs({
    { root = "C:/hv", windows = true, cache = true },
    { root = "C:/" .. string.rep("nested-folder/", 20), windows = true, cache = false },
    { root = "C:/" .. string.rep("á", 30), windows = true, cache = false },
    { root = "/tmp/" .. string.rep("nested-folder/", 20), windows = false, cache = true },
  }) do
    vim.fn.has = function(name)
      return name == "win32" and (case.windows and 1 or 0) or old_has(name)
    end
    vim.uv.fs_stat = function(path, ...)
      if path == vim.fn.stdpath("data") .. "/lazy/lazy.nvim" then
        return { type = "directory" }
      end
      return old_stat(path, ...)
    end
    vim.env.HILVIM_ROOT, vim.env.HILVIM_PORTABLE = case.root, "1"
    local options
    package.loaded.lazy = {
      setup = function(opts)
        options = opts
      end,
    }
    dofile("lua/config/lazy.lua")
    assert(options.performance.cache.enabled == case.cache, "Wrong bytecode cache policy for " .. case.root)
  end
end, debug.traceback)
vim.fn.has, vim.uv.fs_stat = old_has, old_stat
vim.env.HILVIM_ROOT, vim.env.HILVIM_PORTABLE = old_root, old_portable
package.loaded.lazy = old_lazy
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  print("PORTABLE_CACHE_TESTS_OK")
  vim.cmd("qa!")
end
