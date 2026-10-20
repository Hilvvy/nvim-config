return {
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {
      filewatching = "auto",
    },
    config = function(_, opts)
      local windows = vim.fn.has("win32") == 1
      local machine = vim.uv.os_uname().machine
      local rid = windows and "win-x64" or (machine == "aarch64" and "linux-arm64" or "linux-x64")
      local language_server = vim.fs.joinpath(
        vim.fn.stdpath("data"),
        "tools",
        "roslyn-language-server-5.12.0-1.26426.8",
        "tools",
        "net10.0",
        rid,
        "Microsoft.CodeAnalysis.LanguageServer" .. (windows and ".exe" or "")
      )

      vim.lsp.config("roslyn", {
        -- The official platform-specific NuGet bundle is installed in stdpath("data")
        -- because the third-party Mason registry currently points at a 404 release.
        cmd = { language_server, "--stdio" },
        settings = {
          ["csharp|background_analysis"] = {
            -- Keep large solutions responsive by analyzing open files first.
            dotnet_analyzer_diagnostics_scope = "openFiles",
            dotnet_compiler_diagnostics_scope = "openFiles",
          },
        },
      })

      require("roslyn").setup(opts)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Roslyn is the sole C# language server in this configuration.
        omnisharp = { enabled = false },
      },
    },
  },
}
