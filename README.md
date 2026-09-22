# Configuración personal de Neovim

Configuración basada en [LazyVim](https://www.lazyvim.org/) para desarrollo
con Python, Java y C#.

## Requisitos

- Neovim 0.12.x o posterior.
- Git y `curl`.
- Un compilador C en `PATH` para instalar parsers de Treesitter. En Windows,
  se recomienda `gcc` mediante MSYS2 o WinLibs/MinGW-w64.
- `tree-sitter-cli` 0.26 o posterior. En Windows se instala con Winget:
  `winget install tree-sitter.tree-sitter-cli`.
- .NET SDK para C#. `netcoredbg` y `debugpy` se instalan mediante Mason al
  iniciar por primera vez. Roslyn Language Server debe instalarse siguiendo
  las instrucciones vigentes de su proyecto, ya que su paquete oficial de
  NuGet no funciona actualmente como herramienta global en Windows.

La configuración usa las ramas actuales de `nvim-treesitter` y Roslyn, ambas
compatibles con Neovim 0.12.

## Mantenimiento

Si Neovim avisa `E138` al cerrarse, abre de nuevo la configuración y ejecuta
`:ShadaCleanup`. También se eliminan automáticamente los temporales vacíos de
ShaDa con más de un día de antigüedad al iniciar Neovim.
