return {
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {
      filewatching = "auto",
    },
    config = function(_, opts)
      local language_server = vim.fs.joinpath(
        vim.fn.stdpath("data"),
        "tools",
        "roslyn-language-server-5.12.0-1.26426.8",
        "tools",
        "net10.0",
        "win-x64",
        "Microsoft.CodeAnalysis.LanguageServer.exe"
      )

      vim.lsp.config("roslyn", {
        -- The official Windows NuGet bundle is installed in stdpath("data")
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
