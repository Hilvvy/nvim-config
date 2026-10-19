if vim.env.HILVIM_PORTABLE ~= "1" then
  return {}
end

-- Cloud completion is opt-in on shared/offline PCs. Local completion stays on.
local cloud = vim.env.HILVIM_COPILOT == "1"
return {
  { "zbirenbaum/copilot.lua", enabled = cloud },
  { "fang2hou/blink-copilot", enabled = cloud },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
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
