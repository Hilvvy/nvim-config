# Configuración personal de Neovim

Configuración basada en [LazyVim](https://www.lazyvim.org/) para desarrollo
con Python, Java y C#.

## Requisitos

- Neovim 0.11.x.
- Git y `curl`.
- Un compilador C en `PATH` para instalar parsers de Treesitter. En Windows,
  se recomienda `gcc` mediante MSYS2 o WinLibs/MinGW-w64.

La configuración mantiene `nvim-treesitter` en la rama `master` y Roslyn en
una revisión compatible con Neovim 0.11. Al actualizar Neovim a 0.12 o
superior se pueden migrar ambos a sus versiones actuales.

## Mantenimiento

Si Neovim avisa `E138` al cerrarse, abre de nuevo la configuración y ejecuta
`:ShadaCleanup`. También se eliminan automáticamente los temporales vacíos de
ShaDa con más de un día de antigüedad al iniciar Neovim.
