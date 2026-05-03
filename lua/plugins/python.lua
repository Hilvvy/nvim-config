return {

  {
    "mfussenegger/nvim-dap-python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      local sep = package.config:sub(1, 1)
      local is_windows = sep == "\\"

      local function get_python_path()
        local cwd = vim.fn.getcwd()

        local venv_paths = {
          cwd
            .. sep
            .. ".venv"
            .. sep
            .. (is_windows and "Scripts" or "bin")
            .. sep
            .. "python"
            .. (is_windows and ".exe" or ""),
          cwd
            .. sep
            .. "venv"
            .. sep
            .. (is_windows and "Scripts" or "bin")
            .. sep
            .. "python"
            .. (is_windows and ".exe" or ""),
        }

        for _, path in ipairs(venv_paths) do
          if vim.fn.executable(path) == 1 then
            return path
          end
        end

        return is_windows and "python" or "python3"
      end

      require("dap-python").setup(get_python_path())

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch current file",
          program = "${file}",
          pythonPath = get_python_path,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "python",
          request = "launch",
          name = "Launch module",
          module = function()
            return vim.fn.input("Module: ")
          end,
          pythonPath = get_python_path,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "python",
          request = "launch",
          name = "Launch module (auto)",
          module = function()
            local file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p")
            local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")

            file = file:gsub("\\", "/")
            cwd = cwd:gsub("\\", "/")

            if not cwd:match("/$") then
              cwd = cwd .. "/"
            end

            local rel = file

            if rel:sub(1, #cwd) == cwd then
              rel = rel:sub(#cwd + 1)
            end

            rel = rel:gsub("%.py$", "")
            rel = rel:gsub("/", ".")

            return rel
          end,
          cwd = function()
            return vim.fn.getcwd()
          end,
          pythonPath = get_python_path,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "python",
          request = "launch",
          name = "Debug pytest current file",
          module = "pytest",
          args = {
            "${file}",
            "-v",
          },
          pythonPath = get_python_path,
          console = "integratedTerminal",
          justMyCode = false,
        },
      }

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

      map("n", "<leader>dpf", function()
        require("dap-python").test_method()
      end, { desc = "Debug Python: Test Method" })

      map("n", "<leader>dpc", function()
        require("dap-python").test_class()
      end, { desc = "Debug Python: Test Class" })
    end,
  },
}
