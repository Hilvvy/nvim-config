local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Neovim's bytecode cache URI-encodes the full module path into one filename.
-- Deep portable installations can exceed Windows' 255-character component limit,
-- even when long paths are enabled. Keep fast caching for short installations.
local portable_root = vim.env.HILVIM_ROOT or ""
local long_portable_path = vim.fn.has("win32") == 1
  and vim.env.HILVIM_PORTABLE == "1"
  and #vim.uri_encode(vim.fs.normalize(portable_root), "rfc2396") > 100
if long_portable_path and vim.loader then
  vim.loader.enable(false)
end

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.lang.java" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- Custom plugins load on demand unless they explicitly opt out. This keeps
    -- startup focused on the UI and editing essentials.
    lazy = true,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = vim.env.HILVIM_PORTABLE ~= "1", -- portable bundles work offline
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  change_detection = { enabled = vim.env.HILVIM_PORTABLE ~= "1" },
  performance = {
    cache = { enabled = not long_portable_path },
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
