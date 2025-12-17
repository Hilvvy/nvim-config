-- ~/.config/nvim/lua/plugins/kanagawa.lua (create this file if it doesn't exist)
return {
  "rebelot/kanagawa.nvim",
  lazy = false, -- Load immediately for colorscheme
  priority = 1000, -- High priority
  config = function()
    -- Set these before setup for correct sizing
    vim.o.laststatus = 2 -- Always show status line
    vim.o.cmdheight = 1 -- Adjust command height

    require("kanagawa").setup({
      compile = true, -- Enable compilation for best results (run :KanagawaCompile after config changes)
      theme = "dragon", -- Or "lotus", "dragon", "all"
      -- Other options like functionStyle, dimInactive, etc. can go here [1, 6]
      functionStyle = {
        bold = true,
        italic = true,
      },
      dimInactive = true,
    })

    -- Load the colorscheme
    vim.cmd("colorscheme kanagawa-dragon") -- Or kanagawa-lotus, kanagawa-dragon, etc.
    vim.cmd("hi Normal guibg=#0e0d0d")
    vim.cmd("hi NormalNC guibg=#0a0a0c")
  end,
}
