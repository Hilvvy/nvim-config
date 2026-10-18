local c = { bg = "#18181c", fg = "#cdcad2", muted = "#777381", accent = "#a497b3" }

return {
  { "LazyVim/LazyVim", opts = { colorscheme = "vague" } },
  {
    "vague-theme/vague.nvim",
    lazy = false,
    priority = 1000,
    keys = {
      {
        "<leader>ut",
        function()
          vim.g.personal_transparent = not vim.g.personal_transparent
          require("vague").setup({ transparent = vim.g.personal_transparent })
          vim.cmd.colorscheme("vague")
        end,
        desc = "Toggle fondo transparente",
      },
    },
    opts = {
      bold = false,
      italic = false,
      colors = {
        bg = c.bg,
        inactiveBg = c.bg,
        fg = c.fg,
        line = "#25242c",
        comment = c.muted,
        func = "#bc96b0",
        keyword = "#9293b3",
        string = "#aaa394",
        number = "#a48bae",
        constant = "#aaa0bc",
        type = "#9aafb0",
        builtin = "#a4b5ad",
        property = c.fg,
        parameter = c.fg,
        operator = "#aaa7b2",
        visual = "#35313f",
        search = "#494052",
        error = "#cf8585",
        warning = "#c5ac83",
        hint = "#9b98b5",
        plus = "#91a68d",
        delta = "#c5ac83",
      },
      on_highlights = function(hl)
        local bg = vim.g.personal_transparent and "NONE" or c.bg
        hl.Normal = { fg = c.fg, bg = bg }
        hl.NormalNC = { fg = c.fg, bg = bg }
        hl.SignColumn = { bg = bg }
        hl.FoldColumn = { bg = bg }
        hl.NormalFloat = { fg = c.fg, bg = bg }
        hl.FloatBorder = { fg = bg, bg = bg }
        hl.FloatTitle = { fg = c.accent, bg = bg }
        -- Keep floating surfaces flush with the editor; selection stays visible.
        for _, group in ipairs({
          "Pmenu",
          "PmenuSbar",
          "SnacksNormal",
          "SnacksNormalNC",
          "SnacksPickerNormal",
          "SnacksPickerInput",
          "SnacksPickerList",
          "SnacksPickerPreview",
          "SnacksInputNormal",
          "SnacksNotifierNormal",
          "SnacksNotifierHistory",
          "TelescopeNormal",
          "TelescopePromptNormal",
          "TelescopeResultsNormal",
          "TelescopePreviewNormal",
          "BlinkCmpMenu",
          "BlinkCmpDoc",
          "BlinkCmpDocSignature",
          "BlinkCmpSignatureHelp",
          "WhichKeyNormal",
          "NoicePopup",
          "NoicePopupmenu",
          "NoiceMini",
        }) do
          hl[group] = { fg = c.fg, bg = bg }
        end
        hl.WinSeparator = { fg = "#302d37", bg = c.bg }
        hl.CursorLineNr = { fg = c.accent }
        hl.LineNr = { fg = "#625e6b" }
        hl.EndOfBuffer = { fg = c.bg, bg = vim.g.personal_transparent and "NONE" or c.bg }
        hl.StatusLine = { fg = c.muted, bg = c.bg }
        hl.StatusLineNC = { fg = c.muted, bg = c.bg }
        hl.SnacksDashboardHeader = { fg = c.accent }
        hl.SnacksDashboardDesc = { fg = c.fg }
        hl.SnacksDashboardKey = { fg = c.accent }
        hl.SnacksDashboardFooter = { fg = c.muted }
        hl.SnacksPickerDirectory = { fg = c.muted }
        hl.SnacksIndent = { fg = "#2c2932" }
        hl.SnacksIndentScope = { fg = "#62586e" }
      end,
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = { "", "" },
        indicator = { style = "none" },
        show_buffer_icons = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        diagnostics = false,
      },
      highlights = {
        fill = { bg = c.bg },
        background = { fg = c.muted, bg = c.bg },
        buffer_visible = { fg = c.muted, bg = c.bg },
        buffer_selected = { fg = c.accent, bg = c.bg, bold = false, italic = false },
        modified = { fg = c.accent, bg = c.bg },
        modified_selected = { fg = c.accent, bg = c.bg },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local plain = { fg = c.muted, bg = c.bg }
      local theme = {}
      local mode_colors = {
        normal = "#9293b3", -- dusty blue
        insert = "#91a68d", -- muted sage
        visual = "#b09ab9", -- smoky lilac
        replace = "#cf8585", -- faded red
        command = "#c5ac83", -- soft amber
        terminal = "#9aafb0", -- gray teal
        inactive = c.muted,
      }
      for mode, color in pairs(mode_colors) do
        theme[mode] = { a = { fg = color, bg = c.bg }, b = plain, c = plain }
      end
      opts.options.theme = theme
      opts.options.icons_enabled = false
      opts.options.component_separators = ""
      opts.options.section_separators = ""
      opts.sections = {
        lualine_a = { { "mode", fmt = string.lower } },
        lualine_b = { "branch" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          {
            function()
              return "debug " .. require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] and require("dap").status() ~= ""
            end,
          },
          { "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
        },
        lualine_y = { "filetype" },
        lualine_z = { "location" },
      }
    end,
  },
  {
    "folke/noice.nvim",
    opts = {
      cmdline = { view = "cmdline" },
      presets = { command_palette = false, lsp_doc_border = false },
      views = { hover = { border = { style = "none" } }, popup = { border = { style = "none" } } },
    },
  },
  { "folke/which-key.nvim", opts = { win = { border = "none" } } },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      completion = { menu = { border = "none" }, documentation = { window = { border = "none" } } },
      signature = { window = { border = "none" } },
    },
  },
}
