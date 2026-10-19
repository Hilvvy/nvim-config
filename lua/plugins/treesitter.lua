-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
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
