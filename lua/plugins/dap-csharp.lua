return {
  {
    "NicholasMata/nvim-dap-cs",
    ft = { "cs", "csx" },
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap = require("dap")
      local is_windows = package.config:sub(1, 1) == "\\"
      local netcoredbg

      if is_windows then
        -- Mason's .cmd shim can exit before DAP completes its stdio handshake.
        -- Call the actual executable instead.
        netcoredbg = vim.fs.joinpath(
          vim.fn.stdpath("data"),
          "mason",
          "packages",
          "netcoredbg",
          "netcoredbg",
          "netcoredbg.exe"
        )
      else
        netcoredbg = vim.fn.exepath("netcoredbg")
        if netcoredbg == "" then
          netcoredbg = "netcoredbg"
        end
      end

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg,
        args = { "--interpreter=vscode" },
      }

      local function get_dll_path()
        local candidates = vim.fn.globpath(vim.fn.getcwd(), "**/bin/Debug/*/*.dll", false, true)
        return vim.fn.input("Path to dll: ", candidates[1] or vim.fn.getcwd(), "file")
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
            return require("dap.utils").pick_process({ filter = vim.fn.fnamemodify(vim.fn.getcwd(), ":t") })
          end,
        },
      }

      if is_windows then
        local session = require("dap.session")
        local set_breakpoints = session.set_breakpoints

        session.set_breakpoints = function(self, breakpoints, on_done)
          local get_name = vim.api.nvim_buf_get_name
          vim.api.nvim_buf_get_name = function(buffer)
            return get_name(buffer):gsub("/", "\\")
          end

          local ok, result = xpcall(function()
            return set_breakpoints(self, breakpoints, on_done)
          end, debug.traceback)
          vim.api.nvim_buf_get_name = get_name

          if not ok then
            error(result)
          end
          return result
        end
      end

      vim.keymap.set("n", "<leader>da", function()
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        local function attach()
          dap.run({
            type = "coreclr",
            request = "attach",
            name = "Auto-reattach",
            processId = function()
              return require("dap.utils").pick_process({ filter = project_name })
            end,
          })
        end

        if dap.session() then
          dap.terminate()
          vim.defer_fn(attach, 200)
        else
          attach()
        end
      end, { buffer = 0, desc = "Debug: Re-attach" })
    end,
  },
}
