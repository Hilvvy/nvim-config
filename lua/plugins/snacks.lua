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
      dashboard = {
        enabled = true,
        preset = {
          header = [[
██╗  ██╗██╗██╗     ██╗   ██╗██╗███╗   ███╗
██║  ██║██║██║     ██║   ██║██║████╗ ████║
███████║██║██║     ██║   ██║██║██╔████╔██║
██╔══██║██║██║     ██║   ██║██║██║╚██╔╝██║
██║  ██║██║███████╗╚██████╔╝██║██║ ╚═╝ ██║
╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝╚═╝     ╚═╝
]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.dashboard.pick('projects')" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
            },
            { icon = " ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
            { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },

            -- extras útiles
            { icon = " ", key = "e", desc = "Explorer", action = ":lua Snacks.explorer()" },
            { icon = " ", key = "d", desc = "Debug Continue", action = ":lua require('dap').continue()" },
            { icon = " ", key = "k", desc = "Keymaps", action = ":lua Snacks.dashboard.pick('keymaps')" },

            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
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
