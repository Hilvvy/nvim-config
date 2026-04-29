-- ~/.config/nvim/lua/plugins/snacks-ui.lua
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    init = function()
      -- Desactivamos Netrw para evitar que aparezca el explorador feo
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    keys = {
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Toggle Explorer",
      },
    },
    opts = {
      dashboard = { enabled = true },
      explorer = {
        enabled = true,
        replace_netrw = false, -- Evita que snacks se abra solo
      },
      picker = {
        layout = { preset = "ivy" },
        sources = {
          explorer = {
            auto_close = true,
            layout = {
              preset = "default",
              layout = {
                box = "vertical",
                width = 0.8,
                height = 0.8,
                border = "rounded",
                title = " Explorer ",
                title_pos = "center",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
            },
          },
        },
        win = {
          input = {
            keys = {
              ["<Esc>"] = { "close", mode = { "n", "i" } },
            },
          },
        },
      },
    },
  },
}
