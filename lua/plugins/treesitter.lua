-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  -- `main` requires Neovim 0.12. Keep the compatible branch while this
  -- configuration targets Neovim 0.11.
  branch = "master",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "c",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "elixir",
      "heex",
      "javascript",
      "html",
    },
  },
}
