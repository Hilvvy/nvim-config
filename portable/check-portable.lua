vim.defer_fn(function()
  local ok, err = xpcall(function()
    local root = vim.fs.normalize(vim.env.HILVIM_ROOT):lower()
    for _, key in ipairs({ "config", "data", "cache", "state" }) do
      local path = vim.fs.normalize(vim.fn.stdpath(key)):lower()
      assert(path:sub(1, #root + 1) == root .. "/", "External " .. key .. ": " .. path)
    end
    assert(vim.g.colors_name == "vague", "Missing Hilvim theme")
    for _, tool in ipairs({
      "git",
      "rg",
      "fd",
      "lazygit",
      "gcc",
      "tree-sitter",
      "node",
      "python",
      "java",
      "dotnet",
      "ruff",
    }) do
      local path = vim.fs.normalize(vim.fn.exepath(tool)):lower()
      assert(path:sub(1, #root + 1) == root .. "/", "External/missing tool: " .. tool .. " " .. path)
    end
    local function run(cmd)
      local result = vim.system(cmd, { text = true, cwd = vim.env.HILVIM_ROOT }):wait(30000)
      assert(result.code == 0, table.concat(cmd, " ") .. ": " .. (result.stderr or ""))
      return result.stdout or ""
    end
    run({ "git", "--version" })
    run({ "rg", "--version" })
    run({ "fd", "--version" })
    run({ "lazygit", "--version" })
    run({ "gcc", "--version" })
    run({ "tree-sitter", "--version" })
    run({ "node", "--version" })
    run({ "python", "-c", "import debugpy,venv,ssl; print(debugpy.__version__)" })
    run({ "ruff", "--version" })
    run({ "java", "-version" })
    run({ "dotnet", "--list-sdks" })
    local runtime = run({ "dotnet", "--list-runtimes" })
    assert(runtime:find("Microsoft.NETCore.App 10.", 1, true), "Roslyn needs .NET 10 runtime")
    local function dap_handshake(command)
      local output = ""
      local job = vim.fn.jobstart(command, {
        on_stdout = function(_, lines)
          output = output .. table.concat(lines, "\n")
        end,
      })
      assert(job > 0, "Cannot start debug adapter: " .. command[1])
      local request = vim.json.encode({
        seq = 1,
        type = "request",
        command = "initialize",
        arguments = { adapterID = "portable-check", clientID = "nvim" },
      })
      vim.fn.chansend(job, "Content-Length: " .. #request .. "\r\n\r\n" .. request)
      local initialized = vim.wait(15000, function()
        return output:match('"success"%s*:%s*true') ~= nil
      end, 100)
      vim.fn.jobstop(job)
      assert(initialized, "Debug adapter handshake failed: " .. command[1])
    end
    dap_handshake({ vim.fn.exepath("python"), "-m", "debugpy.adapter" })
    dap_handshake({
      vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe",
      "--interpreter=vscode",
    })
    local ts = require("nvim-treesitter")
    assert(vim.tbl_contains(ts.get_installed("parsers"), "c_sharp"), "Missing C# parser")
    vim.treesitter.language.add("c_sharp")
    require("lazyvim.config").load("keymaps")
    assert(vim.fn.maparg("<leader>gg", "n") ~= "", "Lazygit mapping missing")
    local testdir = vim.fs.joinpath(vim.env.TEMP, "portable-check")
    vim.fn.mkdir(testdir, "p")
    local cfile = vim.fs.joinpath(testdir, "check.c")
    local cexe = vim.fs.joinpath(testdir, "check.exe")
    vim.fn.writefile({ "int main(void) { return 0; }" }, cfile)
    run({ "gcc", cfile, "-o", cexe })
    run({ cexe })
    local javafile = vim.fs.joinpath(testdir, "PortableHello.java")
    vim.fn.writefile(
      { 'class PortableHello { public static void main(String[] args) { System.out.println("ok"); } }' },
      javafile
    )
    run({ "javac", "-d", testdir, javafile })
    assert(run({ "java", "-cp", testdir, "PortableHello" }):find("ok", 1, true), "Java sample failed")
    local csdir = vim.fs.joinpath(testdir, "dotnet")
    vim.fn.mkdir(csdir, "p")
    local csproject = vim.fs.joinpath(csdir, "Check.csproj")
    local framework = "net" .. assert(run({ "dotnet", "--version" }):match("^(%d+)")) .. ".0"
    vim.fn.writefile({
      '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>'
        .. framework
        .. "</TargetFramework><NuGetAudit>false</NuGetAudit></PropertyGroup></Project>",
    }, csproject)
    vim.fn.writefile({ 'System.Console.WriteLine("ok");' }, vim.fs.joinpath(csdir, "Program.cs"))
    local nuget = vim.fs.joinpath(csdir, "NuGet.Config")
    vim.fn.writefile({ "<configuration><packageSources><clear /></packageSources></configuration>" }, nuget)
    run({ "dotnet", "restore", csproject, "--configfile", nuget, "--nologo" })
    run({ "dotnet", "build", csproject, "--no-restore", "--nologo" })
    assert(
      run({ "dotnet", vim.fs.joinpath(csdir, "bin/Debug", framework, "Check.dll") }):find("ok", 1, true),
      "C# sample failed"
    )
    local pyfile = vim.fs.joinpath(testdir, "check.py")
    vim.fn.writefile({ "[tool.pyright]", 'include = ["check.py"]' }, vim.fs.joinpath(testdir, "pyproject.toml"))
    vim.fn.writefile({ "value = 42", "print(value)" }, pyfile)
    vim.cmd.edit(vim.fn.fnameescape(pyfile))
    assert(
      vim.wait(30000, function()
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          if client.initialized then
            names[client.name] = true
          end
        end
        return names.pyright and names.ruff
      end, 100),
      "Python LSPs did not initialize: " .. vim.inspect(vim.lsp.get_clients({ bufnr = 0 }))
    )
    require("dap-python") -- loaded by the Python filetype
    local adapter
    require("dap").adapters.python(function(value)
      adapter = value
    end, { request = "launch" })
    assert(
      adapter.command:lower():sub(1, #root) == root:gsub("/", "\\")
        or vim.fs.normalize(adapter.command):lower():sub(1, #root) == root,
      "External debugpy interpreter"
    )
    require("lazy").load({ plugins = { "blink.cmp" } })
    assert(package.loaded["blink.cmp"], "Completion did not load")
    assert(
      vim.wait(5000, function()
        return require("blink.cmp.fuzzy").implementation_type == "rust"
      end, 50),
      "Native completion did not initialize"
    )
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop()
    end
    vim.wait(3000, function()
      return #vim.lsp.get_clients() == 0
    end, 100)
    io.stdout:write(
      "HILVIM_PORTABLE_OK: isolated paths, bundled tools, Python LSP/DAP, .NET DAP, Java, C compiler, parser and Git\n"
    )
  end, debug.traceback)
  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end, 100)
