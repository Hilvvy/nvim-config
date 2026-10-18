-- Run by install.ps1 after Lazy restores the pinned plugin versions.
vim.defer_fn(function()
  local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter" } })
    local registry = require("mason-registry")
    local refreshed, refresh_error
    registry.refresh(function(success, message)
      refreshed, refresh_error = success, message
    end)
    assert(
      vim.wait(120000, function()
        return refreshed ~= nil
      end, 100),
      "Mason registry refresh timed out"
    )
    assert(refreshed, vim.inspect(refresh_error))
    local packages = {
      "debugpy",
      "netcoredbg",
      "jdtls",
      "java-debug-adapter",
      "java-test",
      "pyright",
      "ruff",
      "lua-language-server",
      "stylua",
      "vtsls",
      "json-lsp",
      "tailwindcss-language-server",
      "marksman",
      "markdownlint-cli2",
      "markdown-toc",
    }
    for _, name in ipairs(packages) do
      local package = registry.get_package(name)
      if not package:is_installed() and not package:is_installing() then
        package:install()
      end
    end
    local finished = vim.wait(600000, function()
      for _, name in ipairs(packages) do
        if registry.get_package(name):is_installing() then
          return false
        end
      end
      return true
    end, 200)
    assert(finished, "Mason installs timed out; inspect :Mason and retry the installer")
    local missing = {}
    for _, name in ipairs(packages) do
      if not registry.get_package(name):is_installed() then
        missing[#missing + 1] = name
      end
    end
    assert(#missing == 0, "Mason failed: " .. table.concat(missing, ", "))
    local config = require("lazy.core.config").plugins["nvim-treesitter"]
    local opts = require("lazy.core.plugin").values(config, "opts", false)
    require("nvim-treesitter").install(opts.ensure_installed):wait(300000)
    for _, parser in ipairs(opts.ensure_installed) do
      assert(#vim.api.nvim_get_runtime_file("parser/" .. parser .. ".*", false) > 0, "Missing parser: " .. parser)
    end
    print("HILVIM_BOOTSTRAP_OK")
  end, debug.traceback)
  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end, 100)
