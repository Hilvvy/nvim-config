if vim.env.HILVIM_PORTABLE ~= "1" then
  return {}
end

-- Cloud completion is opt-in on shared/offline PCs. Local completion stays on.
local cloud = vim.env.HILVIM_COPILOT == "1"
return {
  { "lewis6991/gitsigns.nvim", enabled = vim.fn.executable("git") == 1 },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if vim.env.HILVIM_HOST_TOOLS == "1" and vim.fn.executable("node") == 0 then
        opts.servers = opts.servers or {}
        for _, name in ipairs({ "pyright", "vtsls", "jsonls", "tailwindcss" }) do
          opts.servers[name] = vim.tbl_deep_extend("force", opts.servers[name] or {}, { enabled = false })
        end
      end
    end,
  },
  { "zbirenbaum/copilot.lua", enabled = cloud },
  { "fang2hou/blink-copilot", enabled = cloud },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      local path = vim.fs.joinpath(vim.env.HILVIM_ROOT, "bundle.json")
      local manifest = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
      if manifest.hostTools and manifest.blink then
        -- Pinned portable assets already have their tag/SHA in the build manifest.
        -- Avoid Blink's Git subprocesses even when Git is not installed. Its native
        -- library still goes through the plugin's own checksum verification.
        require("blink.cmp.fuzzy.download.git").get_version = function()
          return require("blink.cmp.lib.async").task.new(function(resolve)
            resolve(manifest.blink)
          end)
        end
      end
      opts.fuzzy = vim.tbl_deep_extend("force", opts.fuzzy or {}, {
        implementation = "rust",
        -- The matching native library and its tag metadata ship in the bundle.
        prebuilt_binaries = { download = true },
      })
      if not cloud and opts.sources and type(opts.sources.default) == "table" then
        opts.sources.default = vim.tbl_filter(function(name)
          return name ~= "copilot"
        end, opts.sources.default)
      end
      if not cloud and opts.sources and opts.sources.providers then
        opts.sources.providers.copilot = nil
      end
    end,
  },
}
