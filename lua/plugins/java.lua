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

        local jdtls = require("jdtls")
        pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
        pcall(function()
          require("jdtls.dap").setup_dap_main_class_configs()
        end)

        vim.keymap.set("n", "<leader>jr", "<cmd>terminal ant run<cr>", {
          buffer = bufnr,
          desc = "Java Ant: Run",
        })
        vim.keymap.set("n", "<leader>jc", "<cmd>terminal ant compile<cr>", {
          buffer = bufnr,
          desc = "Java Ant: Compile",
        })
        vim.keymap.set("n", "<leader>jdt", jdtls.test_class, {
          buffer = bufnr,
          desc = "Java: Debug Test Class",
        })
        vim.keymap.set("n", "<leader>jdm", jdtls.test_nearest_method, {
          buffer = bufnr,
          desc = "Java: Debug Test Method",
        })
      end

      return opts
    end,
  },
}
