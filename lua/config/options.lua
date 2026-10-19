-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.laststatus = 3
vim.opt.cmdheight = 1
vim.opt.winborder = "none"
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.fillchars:append({ eob = " " })
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
