-- ~/.config/nvim/lua/plugins/kanagawa.lua
return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.o.laststatus = 2
    vim.o.cmdheight = 1

    require("kanagawa").setup({
      compile = true,
      theme = "dragon",
      functionStyle = {
        bold = true,
        italic = true,
      },
      dimInactive = true,
    })

    vim.cmd("colorscheme kanagawa-dragon")

    -- =========================
    -- 🎨 Fondo sólido (default)
    -- =========================
    local bg_solid = {
      normal = "#0e0d0d",
      normal_nc = "#0a0a0c",
    }

    local is_transparent = false

    local function set_solid_bg()
      -- base
      vim.api.nvim_set_hl(0, "Normal", { bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = bg_solid.normal_nc })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "FoldColumn", { bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "LineNr", { bg = bg_solid.normal })

      -- floats / snacks
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#54546D", bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "SnacksNormal", { bg = bg_solid.normal })
      vim.api.nvim_set_hl(0, "SnacksBorder", { bg = bg_solid.normal })

      is_transparent = false
    end

    local function set_transparent_bg()
      -- base
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
      vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
      vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })

      -- floats / snacks (con borde bonito)
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#54546D", bg = "none" })
      vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "SnacksBorder", { bg = "none" })

      is_transparent = true
    end

    -- 🟢 Estado inicial
    set_solid_bg()

    -- =========================
    -- 🔀 Toggle con tecla
    -- =========================
    vim.keymap.set("n", "<leader>ut", function()
      if is_transparent then
        set_solid_bg()
      else
        set_transparent_bg()
      end
    end, { desc = "Toggle fondo transparente" })
  end,
}
