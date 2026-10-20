vim.o.more = false
vim.o.swapfile = false
vim.defer_fn(function()
  local ok, err = xpcall(function()
    local root = vim.fs.normalize(vim.env.HILVIM_ROOT)
    for _, key in ipairs({ "config", "data", "cache", "state" }) do
      assert(vim.fs.normalize(vim.fn.stdpath(key)):lower():sub(1, #root + 1) == root:lower() .. "/", key)
    end
    assert(vim.g.colors_name == "vague", "Missing theme")
    for _, tool in ipairs({ "rg", "fd", "lazygit", "ruff" }) do
      assert(vim.fn.executable(tool) == 1, "Missing editor dependency: " .. tool)
    end
    for _, folder in ipairs({ "dotnet", "java", "gcc", "git", "node", "python" }) do
      assert(not vim.uv.fs_stat(root .. "/tools/" .. folder), "Unexpected project toolchain: " .. folder)
    end
    local function run(cmd)
      local result = vim.system(cmd, { text = true }):wait(30000)
      assert(result.code == 0, table.concat(cmd, " ") .. ": " .. (result.stderr or ""))
      return result.stdout or ""
    end
    if vim.fn.executable("git") == 1 then
      run({ "git", "--version" })
    end
    if vim.fn.executable("node") == 1 then
      run({ "node", "--version" })
    end
    run({ "ruff", "--version" })
    local python = vim.fn.exepath("python")
    local function handshake(cmd)
      local output = ""
      local job = vim.fn.jobstart(cmd, {
        on_stdout = function(_, lines)
          output = output .. table.concat(lines, "\n")
        end,
      })
      assert(job > 0, "Cannot start adapter")
      local request = vim.json.encode({
        seq = 1,
        type = "request",
        command = "initialize",
        arguments = { adapterID = "hilvim-check", clientID = "nvim" },
      })
      vim.fn.chansend(job, "Content-Length: " .. #request .. "\r\n\r\n" .. request)
      local initialized = vim.wait(15000, function()
        return output:match('"success"%s*:%s*true') ~= nil
      end, 100)
      vim.fn.jobstop(job)
      assert(initialized, "Adapter handshake failed: " .. cmd[1])
    end
    if python ~= "" then
      handshake({ python, "-I", root .. "/scripts/debugpy-launcher.py" })
    end
    handshake({
      vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe",
      "--interpreter=vscode",
    })
    vim.treesitter.language.add("c_sharp")
    local testdir = vim.fs.joinpath(vim.env.TEMP, "editor-check")
    vim.fn.mkdir(testdir, "p")
    local pyfile = vim.fs.joinpath(testdir, "check.py")
    vim.fn.writefile({ "value = 42", "print(value)" }, pyfile)
    vim.fn.writefile({ "[tool.pyright]", 'include = ["check.py"]' }, vim.fs.joinpath(testdir, "pyproject.toml"))
    vim.cmd.edit(vim.fn.fnameescape(pyfile))
    assert(
      vim.wait(30000, function()
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          if client.initialized then
            names[client.name] = true
          end
        end
        return (vim.fn.executable("node") == 0 or names.pyright) and names.ruff
      end, 100),
      "Python LSPs did not initialize"
    )
    require("dap-python")
    local dap = require("dap")
    dap.adapters.python(function(adapter)
      assert(adapter.command == "python" or vim.fn.exepath(adapter.command) == python, "Adapter interpreter")
      assert(adapter.args[1] == "-I", "Adapter must isolate its private interpreter")
      assert(adapter.args[2]:find("debugpy-launcher.py", 1, true), "Bundled debugpy with host Python")
    end, { request = "launch" })
    dap.adapters.python(function(adapter)
      assert(adapter.type == "server", "Python attach")
    end, { request = "attach", connect = { host = "127.0.0.1", port = 5678 } })
    require("lazyvim.config").load("keymaps")
    assert(vim.fn.maparg("<leader>gg", "n") ~= "", "Missing Git mapping")
    require("lazy").load({ plugins = { "blink.cmp" } })
    assert(
      vim.wait(20000, function()
        return require("blink.cmp.fuzzy").implementation_type == "rust"
      end, 50),
      "Native completion"
    )
    for _, tool in ipairs({ "git", "node", "python", "dotnet", "java", "javac", "gcc", "tree-sitter" }) do
      io.stdout:write(
        "HOST "
          .. tool
          .. ": "
          .. (vim.fn.exepath(tool) ~= "" and vim.fn.exepath(tool) or "not installed (optional)")
          .. "\n"
      )
    end
    if vim.fn.executable("dotnet") == 1 then
      local result = vim.system({ "dotnet", "--list-runtimes" }, { text = true }):wait(10000)
      if not (result.stdout or ""):find("Microsoft.NETCore.App 10.", 1, true) then
        io.stdout:write("NOTE: C# Roslyn requires the host .NET 10 runtime. SDKs for projects are separate.\n")
      else
        local server = vim.fn.stdpath("data")
          .. "/tools/roslyn-language-server-5.12.0-1.26426.8/tools/net10.0/win-x64/Microsoft.CodeAnalysis.LanguageServer.exe"
        run({ server, "--version" })
        io.stdout:write("HOST Roslyn: executable starts using installed .NET runtime\n")
      end
    else
      io.stdout:write("NOTE: Install .NET 10 runtime for Roslyn and a suitable SDK for C# projects.\n")
    end
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop()
    end
    vim.wait(3000, function()
      return #vim.lsp.get_clients() == 0
    end, 100)
    io.stdout:write(
      "HILVIM_EDITOR_OK: editor, native completion, parsers, Ruff and adapters; host Git/runtimes/toolchains\n"
    )
  end, debug.traceback)
  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end, 100)
