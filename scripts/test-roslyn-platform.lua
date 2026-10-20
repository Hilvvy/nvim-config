-- nvim --headless -u NONE -i NONE -c 'luafile scripts/test-roslyn-platform.lua'
local original_has, original_uname, original_config = vim.fn.has, vim.uv.os_uname, vim.lsp.config
local original_roslyn = package.loaded.roslyn
local ok, err = xpcall(function()
  for _, case in ipairs({
    { windows = true, machine = "x86_64", rid = "win-x64", executable = "Microsoft.CodeAnalysis.LanguageServer.exe" },
    { windows = false, machine = "x86_64", rid = "linux-x64", executable = "Microsoft.CodeAnalysis.LanguageServer" },
    { windows = false, machine = "aarch64", rid = "linux-arm64", executable = "Microsoft.CodeAnalysis.LanguageServer" },
  }) do
    vim.fn.has = function(name)
      return name == "win32" and (case.windows and 1 or 0) or original_has(name)
    end
    vim.uv.os_uname = function()
      return { machine = case.machine }
    end
    local captured
    vim.lsp.config = function(name, config)
      assert(name == "roslyn")
      captured = config
    end
    package.loaded.roslyn = { setup = function() end }
    dofile("lua/plugins/roslyn.lua")[1].config(nil, {})
    assert(captured.cmd[1]:find(case.rid, 1, true), "Wrong Roslyn RID")
    assert(vim.fs.basename(captured.cmd[1]) == case.executable, "Wrong server executable")
    assert(captured.cmd[2] == "--stdio", "Wrong transport")
  end
end, debug.traceback)
vim.fn.has, vim.uv.os_uname, vim.lsp.config = original_has, original_uname, original_config
package.loaded.roslyn = original_roslyn
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  print("ROSLYN_PLATFORM_TESTS_OK")
  vim.cmd("qa!")
end
