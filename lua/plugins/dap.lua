return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    opts = {
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
    },
    config = function(_, opts)
      require("dapui").setup(opts)
      require("config.dap").setup_ui()
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "python", "coreclr" })

      -- Language plugins own these adapters and configurations.
      opts.handlers = opts.handlers or {}
      opts.handlers.python = function() end
      opts.handlers.coreclr = function() end
    end,
  },
}
