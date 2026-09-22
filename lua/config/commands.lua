local uv = vim.uv or vim.loop

local function cleanup_shada_temps(minimum_age)
  local shada_dir = vim.fn.stdpath("data") .. "/shada"
  local now = os.time()
  local removed = 0

  for _, path in ipairs(vim.fn.globpath(shada_dir, "main.shada.tmp.?", false, true)) do
    local stat = uv.fs_stat(path)
    local age = stat and now - stat.mtime.sec or 0

    -- ShaDa's temporary files are empty. Keeping recent files avoids touching
    -- one that may belong to another Neovim instance that is still closing.
    if stat and stat.size == 0 and age >= minimum_age and uv.fs_unlink(path) then
      removed = removed + 1
    end
  end

  return removed
end

vim.api.nvim_create_user_command("ShadaCleanup", function()
  local removed = cleanup_shada_temps(60 * 60)
  vim.notify(("ShaDa: %d archivo(s) temporal(es) eliminado(s)."):format(removed))
end, {
  desc = "Remove stale, empty ShaDa temporary files",
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    cleanup_shada_temps(24 * 60 * 60)
  end,
  desc = "Remove stale ShaDa temporary files",
})
