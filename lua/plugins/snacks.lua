local function dashboard_art()
  local ok, lines = pcall(vim.fn.readfile, vim.fn.stdpath("config") .. "/asciiart.txt")
  if not ok then
    return "hilvim /"
  end
  -- Accept the Markdown fences used when sharing the drawing.
  if lines[1] and lines[1]:match("^%s*```") then
    table.remove(lines, 1)
  end
  if lines[#lines] and lines[#lines]:match("^%s*```%s*$") then
    table.remove(lines)
  end
  return #lines > 0 and table.concat(lines, "\n") or "hilvim /"
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    keys = {
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Toggle Explorer",
      },
    },
    opts = {
      dashboard = {
        enabled = true,
        width = 40,
        preset = {
          header = dashboard_art(),
          keys = {
            { key = "f", desc = "buscar archivo", action = ":lua Snacks.dashboard.pick('files')" },
            { key = "g", desc = "buscar texto", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { key = "r", desc = "recientes", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { key = "s", desc = "retomar sesion", action = ":lua require('persistence').load()" },
          },
        },
        sections = {
          { section = "header", padding = 1 },
          { text = "hilvim /", align = "center", hl = "SnacksDashboardHeader", padding = 2 },
          { section = "keys", gap = 1 },
        },
      },
      explorer = { enabled = true, replace_netrw = false },
      notifier = { style = "minimal" },
      input = { win = { border = "none" } },
      styles = { notification_history = { border = "none" } },
      indent = { animate = { enabled = false }, scope = { enabled = true } },
      picker = {
        layout = {
          preset = "ivy",
          layout = {
            box = "vertical",
            row = -1,
            width = 0,
            height = 0.4,
            backdrop = false,
            border = "none",
            { win = "input", height = 1, border = "none" },
            {
              box = "horizontal",
              { win = "list", border = "none" },
              { win = "preview", width = 0.6, border = "none" },
            },
          },
        },
        sources = {
          select = {
            layout = {
              preset = "select",
              layout = {
                box = "vertical",
                width = 0.5,
                height = 0.4,
                min_height = 2,
                border = "none",
                backdrop = false,
                { win = "input", height = 1, border = "none" },
                { win = "list", border = "none" },
                { win = "preview", height = 0.4, border = "none" },
              },
            },
          },
          explorer = {
            auto_close = true,
            layout = {
              preset = "default",
              layout = {
                box = "vertical",
                width = 0.65,
                height = 0.7,
                border = "none",
                backdrop = false,
                { win = "input", height = 1, border = "none" },
                { win = "list", border = "none" },
              },
            },
          },
        },
        win = {
          input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } },
        },
      },
    },
  },
}
