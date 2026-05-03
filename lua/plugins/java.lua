return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    opts = function(_, opts)
      opts.root_dir = function()
        return require("jdtls.setup").find_root({
          "build.xml",
          ".project",
          "pom.xml",
          "build.gradle",
          "settings.gradle",
          ".git",
        })
      end

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          project = {
            sourcePaths = { "src" },
            outputPath = "build/classes",
          },
        },
      })

      local original_on_attach = opts.on_attach

      opts.on_attach = function(client, bufnr)
        if original_on_attach then
          original_on_attach(client, bufnr)
        end

        local dap = require("dap")
        local dapui = require("dapui")
        local jdtls = require("jdtls")

        pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
        pcall(require("jdtls.dap").setup_dap_main_class_configs)

        -- Abrir DAP UI al iniciar debug
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end

        -- IMPORTANTE:
        -- No cerrar DAP UI automáticamente en Java,
        -- para poder ver la consola/output después de terminar.
        dap.listeners.before.event_terminated["dapui_config"] = function(session)
          if session and session.config and session.config.type ~= "java" then
            dapui.close()
          end
        end

        dap.listeners.before.event_exited["dapui_config"] = function(session)
          if session and session.config and session.config.type ~= "java" then
            dapui.close()
          end
        end

        local map = vim.keymap.set

        -- Debug general
        map("n", "<F5>", function()
          dap.continue()
        end, { buffer = bufnr, desc = "Debug: Start/Continue" })

        map("n", "<F10>", function()
          dap.step_over()
        end, { buffer = bufnr, desc = "Debug: Step Over" })

        map("n", "<F11>", function()
          dap.step_into()
        end, { buffer = bufnr, desc = "Debug: Step Into" })

        map("n", "<F12>", function()
          dap.step_out()
        end, { buffer = bufnr, desc = "Debug: Step Out" })

        map("n", "<leader>db", function()
          dap.toggle_breakpoint()
        end, { buffer = bufnr, desc = "Debug: Toggle Breakpoint" })

        map("n", "<leader>dB", function()
          dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { buffer = bufnr, desc = "Debug: Conditional Breakpoint" })

        map("n", "<leader>dx", function()
          dap.terminate()
        end, { buffer = bufnr, desc = "Debug: Terminate" })

        map("n", "<leader>du", function()
          dapui.toggle()
        end, { buffer = bufnr, desc = "Debug: Toggle UI" })

        -- Java / Ant
        map("n", "<leader>jr", "<cmd>terminal ant run<cr>", {
          buffer = bufnr,
          desc = "Java Ant: Run",
        })

        map("n", "<leader>jc", "<cmd>terminal ant compile<cr>", {
          buffer = bufnr,
          desc = "Java Ant: Compile",
        })

        map("n", "<leader>jdt", jdtls.test_class, {
          buffer = bufnr,
          desc = "Java: Debug Test Class",
        })

        map("n", "<leader>jdm", jdtls.test_nearest_method, {
          buffer = bufnr,
          desc = "Java: Debug Test Method",
        })
      end

      return opts
    end,
  },
}
