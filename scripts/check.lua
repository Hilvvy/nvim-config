-- Read-only smoke check: nvim --headless -i NONE -c "luafile scripts/check.lua"
vim.defer_fn(function()
  local ok, err = xpcall(function()
    assert(vim.fn.has("nvim-0.12") == 1, "Neovim >= 0.12 required")
    assert(vim.g.colors_name == "vague", "Expected Vague colorscheme")
    local specs = require("lazy.core.config").plugins
    for _, name in ipairs({ "snacks.nvim", "vague.nvim", "gitsigns.nvim", "roslyn.nvim", "nvim-dap" }) do
      assert(specs[name] and specs[name]._.installed, "Missing plugin: " .. name)
    end
    require("lazy").load({ plugins = { "lualine.nvim", "bufferline.nvim", "telescope.nvim" } })
    local theme = require("lualine").get_config().options.theme
    assert(theme.normal.a.fg ~= theme.insert.a.fg, "Mode colors must differ")
    local float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    assert(float.bg == normal.bg, "Floating backgrounds must match editor")
    local dashboard = require("plugins.snacks")[1].opts.dashboard
    assert(dashboard.sections[2].text == "hilvim /", "Dashboard caption missing")
    assert(not dashboard.preset.header:find("```", 1, true), "Unexpected Markdown fence in art")
    for _, tool in ipairs({ "git", "lazygit", "gcc", "tree-sitter", "node", "python", "java", "dotnet" }) do
      assert(vim.fn.executable(tool) == 1, "Missing executable: " .. tool)
    end
    if vim.fn.has("win32") == 1 then
      local data = vim.fn.stdpath("data")
      assert(
        vim.fn.executable(
          data
            .. "/tools/roslyn-language-server-5.12.0-1.26426.8/tools/net10.0/win-x64/Microsoft.CodeAnalysis.LanguageServer.exe"
        ) == 1,
        "Roslyn bundle missing"
      )
      assert(
        vim.fn.executable(data .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe") == 1,
        "netcoredbg missing"
      )
    end
    print("HILVIM_CHECK_OK")
  end, debug.traceback)
  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end, 100)
