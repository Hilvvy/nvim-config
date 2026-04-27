-- ~/.config/nvim/lua/plugins/snacks-ui.lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = true,
        layout = {
          preset = "sidebar",
          width = 30,
        },
        win = {
          wo = {
            signcolumn = "no",
            number = false,
            relativenumber = false,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },
      },

      picker = {
        layout = {
          preset = "ivy",
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
