-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  -- Solo sobreescribimos opciones, no hacemos require ni setup manual
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
    -- El resto (highlight, indent, etc.) lo maneja LazyVim
  },
}
