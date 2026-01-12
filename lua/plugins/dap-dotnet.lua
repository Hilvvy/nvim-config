return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function()
      local dap = require("dap")

      -- En Windows, netcoredbg a veces necesita detached=false para no "quedarse pegado"
      -- (es un issue conocido en setups con Mason). :contentReference[oaicite:1]{index=1}
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"
      local netcoredbg = mason_bin .. (vim.fn.has("win32") == 1 and "netcoredbg.cmd" or "netcoredbg")

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg,
        args = { "--interpreter=vscode" },
        options = { detached = false },
      }

      local function pick_dll()
        -- intenta agarrar un dll de Debug automáticamente (sirve para consola y webapi)
        local cwd = vim.fn.getcwd()
        local dlls = vim.fn.glob(cwd .. "/**/bin/Debug/**/**/*.dll", true, true)
        if #dlls == 0 then
          return vim.fn.input("Path to dll: ", cwd .. "/bin/Debug/", "file")
        end
        -- si hay muchos, te deja escoger
        return vim.fn.inputlist(vim.list_extend({ "Pick dll:" }, dlls))
            and dlls[vim.fn.inputlist(vim.list_extend({ "Pick dll:" }, dlls))]
          or dlls[1]
      end

      dap.configurations.cs = {
        {
          name = "Launch (pick dll) - Console/Web",
          type = "coreclr",
          request = "launch",
          program = pick_dll,
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
        },
        {
          name = "Launch (ASP.NET) - Development",
          type = "coreclr",
          request = "launch",
          program = pick_dll,
          cwd = "${workspaceFolder}",
          env = {
            ASPNETCORE_ENVIRONMENT = "Development",
          },
          console = "integratedTerminal",
        },
        {
          name = "Attach (pick process) - useful for dotnet watch",
          type = "coreclr",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      }
    end,
  },
}
