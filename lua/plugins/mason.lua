local function append_unique(items, values)
  for _, value in ipairs(values) do
    if not vim.tbl_contains(items, value) then
      table.insert(items, value)
    end
  end
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or { "github:mason-org/mason-registry" }
      append_unique(opts.registries, { "github:Crashdummyy/mason-registry" })

      opts.ensure_installed = opts.ensure_installed or {}
      append_unique(opts.ensure_installed, {
        "debugpy",
        "netcoredbg",
      })
    end,
  },
}
