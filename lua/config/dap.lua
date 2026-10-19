local M = {}

function M.setup_ui()
  local dap = require("dap")
  local dapui = require("dapui")
  local keep_open = { coreclr = true, java = true }

  dap.listeners.after.event_initialized.personal_dapui = function()
    dapui.open()
  end

  local function close_if_needed(session)
    local config = session and session.config or {}
    if not keep_open[config.type] then
      dapui.close()
    end
  end

  dap.listeners.before.event_terminated.personal_dapui = close_if_needed
  dap.listeners.before.event_exited.personal_dapui = close_if_needed
end

return M
