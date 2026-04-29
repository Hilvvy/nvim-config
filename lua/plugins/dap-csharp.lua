return {
  { "mfussenegger/nvim-dap" },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    config = function()
      require("dapui").setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.45 },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.15 },
            },
            size = 42,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
      })
    end,
  },
  {
    "NicholasMata/nvim-dap-cs",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Detectar OS
      local sep = package.config:sub(1, 1)
      local is_windows = sep == "\\"

      -- Path a netcoredbg compatible con Windows y Linux/Mac
      local netcoredbg_path = vim.fn.stdpath("data")
        .. sep
        .. "mason"
        .. sep
        .. "packages"
        .. sep
        .. "netcoredbg"
        .. sep
        .. "netcoredbg"
        .. sep
        .. "netcoredbg"
        .. (is_windows and ".exe" or "")

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      -- Función para construir el path al dll
      local function get_dll_path()
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")
        local debug_path = cwd .. sep .. "bin" .. sep .. "Debug" .. sep
        local found = vim.fn.glob(debug_path .. "net*", false, true)
        local framework = #found > 0 and vim.fn.fnamemodify(found[1], ":t") or "net9.0"
        local default = debug_path .. framework .. sep .. project_name .. ".dll"
        return vim.fn.input("Path to dll: ", default, "file")
      end

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch",
          request = "launch",
          program = get_dll_path,
          cwd = function()
            return vim.fn.getcwd()
          end,
          stopAtEntry = false,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "coreclr",
          name = "Launch (stop at entry)",
          request = "launch",
          program = get_dll_path,
          cwd = function()
            return vim.fn.getcwd()
          end,
          stopAtEntry = true,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "coreclr",
          name = "Attach",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
        {
          type = "coreclr",
          name = "Attach (dotnet/watch)",
          request = "attach",
          processId = function()
            return require("dap.utils").pick_process({ filter = "dotnet" })
          end,
        },
        {
          type = "coreclr",
          name = "Attach (WebAPI/MVC)",
          request = "attach",
          processId = function()
            local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            return require("dap.utils").pick_process({ filter = project_name })
          end,
        },
      }

      -- Fix para Windows: nvim-dap usa forward slashes pero netcoredbg necesita backslashes
      if is_windows then
        local session_mod = require("dap.session")
        local orig_bp = session_mod.set_breakpoints
        session_mod.set_breakpoints = function(self, bps, on_done)
          local orig_get_name = vim.api.nvim_buf_get_name
          vim.api.nvim_buf_get_name = function(buf)
            local name = orig_get_name(buf)
            return name:gsub("/", "\\")
          end
          local result = orig_bp(self, bps, on_done)
          vim.api.nvim_buf_get_name = orig_get_name
          return result
        end
      end

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      local map = vim.keymap.set
      map("n", "<F5>", function()
        dap.continue()
      end, { desc = "Debug: Continue" })
      map("n", "<F10>", function()
        dap.step_over()
      end, { desc = "Debug: Step Over" })
      map("n", "<F11>", function()
        dap.step_into()
      end, { desc = "Debug: Step Into" })
      map("n", "<F12>", function()
        dap.step_out()
      end, { desc = "Debug: Step Out" })
      map("n", "<leader>db", function()
        dap.toggle_breakpoint()
      end, { desc = "Debug: Toggle Breakpoint" })
      map("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Debug: Conditional Breakpoint" })
      map("n", "<leader>du", function()
        dapui.toggle()
      end, { desc = "Debug: Toggle UI" })
      map("n", "<leader>dx", function()
        dap.terminate()
      end, { desc = "Debug: Terminate" })
      map("n", "<leader>da", function()
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        local session = dap.session()
        if session then
          dap.terminate()
          vim.wait(500)
        end
        dap.run({
          type = "coreclr",
          request = "attach",
          name = "Auto-reattach",
          processId = function()
            return require("dap.utils").pick_process({ filter = project_name })
          end,
        })
      end, { desc = "Debug: Re-attach" })
    end,
  },
}
