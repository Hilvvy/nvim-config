-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  -- `main` requires Neovim 0.12. Keep the compatible branch while this
  -- configuration targets Neovim 0.11.
  branch = "master",
  -- Treesitter must be available before opening source buffers.
  lazy = false,
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "c",
      "c_sharp",
      "java",
      "lua",
      "python",
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
