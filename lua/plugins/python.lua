return {
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local dap = require("dap")
      local is_windows = package.config:sub(1, 1) == "\\"

      local function get_python_path()
        local cwd = vim.fn.getcwd()
        local executable = is_windows and "python.exe" or "python"
        local bin_dir = is_windows and "Scripts" or "bin"

        for _, venv in ipairs({ ".venv", "venv" }) do
          local path = table.concat({ cwd, venv, bin_dir, executable }, package.config:sub(1, 1))
          if vim.fn.executable(path) == 1 then
            return path
          end
        end

        return is_windows and "python" or "python3"
      end

      local host_tools = vim.env.HILVIM_HOST_TOOLS == "1"
      local adapter_python = host_tools and get_python_path()
        or vim.env.HILVIM_PORTABLE == "1" and vim.fs.joinpath(vim.env.HILVIM_ROOT, "tools", "python", "python.exe")
        or "debugpy-adapter"
      require("dap-python").setup(adapter_python)
      if vim.env.HILVIM_PORTABLE == "1" then
        local resolve_adapter = dap.adapters.python
        dap.adapters.python = function(callback, config)
          resolve_adapter(function(adapter)
            if adapter.type == "executable" then
              if host_tools then
                adapter.args = { "-I", vim.fs.joinpath(vim.env.HILVIM_ROOT, "scripts", "debugpy-launcher.py") }
              else
                table.insert(adapter.args, 1, "-I")
              end
            end
            callback(adapter)
          end, config)
        end
      end

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
            local file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p"):gsub("\\", "/")
            local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("\\", "/"):gsub("/$", "") .. "/"
            local relative = file:sub(1, #cwd) == cwd and file:sub(#cwd + 1) or file
            return relative:gsub("%.py$", ""):gsub("/", ".")
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
          args = { "${file}", "-v" },
          pythonPath = get_python_path,
          console = "integratedTerminal",
          justMyCode = false,
        },
      }

      vim.keymap.set("n", "<leader>dpf", function()
        require("dap-python").test_method()
      end, { buffer = 0, desc = "Debug Python: Test Method" })

      vim.keymap.set("n", "<leader>dpc", function()
        require("dap-python").test_class()
      end, { buffer = 0, desc = "Debug Python: Test Class" })
    end,
  },
}
