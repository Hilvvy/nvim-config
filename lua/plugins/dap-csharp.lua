return {
  -- Asegura nvim-dap (por si acaso tu setup lo dejó fuera)
  { "mfussenegger/nvim-dap" },

  -- UI (LazyVim usualmente ya lo trae, pero no estorba)
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    config = function()
      require("dapui").setup()
    end,
  },

  -- El “secreto” de la guía: autoconfig para C#
  {
    "NicholasMata/nvim-dap-cs",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      -- Usa netcoredbg (instalado por Mason)
      require("dap-cs").setup()

      -- Abrir/cerrar UI automáticamente (igual que en la guía)
      local dap, dapui = require("dap"), require("dapui")
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
    end,
  },
}
