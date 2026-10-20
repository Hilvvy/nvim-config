# Hilvim

Configuración personal de [Neovim](https://neovim.io/) basada en
[LazyVim](https://www.lazyvim.org/). Terminal sobria, fondo carbón y acentos
malva apagados. Dashboard con arte Unicode, menús sin bordes, superficies
uniformes y una barra de estado cuyo modo cambia de color.

Preparada para Windows x64 con Neovim >= 0.12, C#/.NET, Python y Java.
Incluye soporte de TypeScript, JSON, Markdown y Tailwind mediante LazyVim Extras.

## Portable para USB (Windows x64)

El paquete predeterminado `dist/Hilvim-Portable-Editor.zip` contiene Neovim,
Hilvim, plugins, parsers, Lazygit, servidores de lenguaje y debuggers.
No incluye Git, Node, Python, SDKs/runtimes .NET, JDK ni GCC: usa los instalados en la
PC, como un editor con extensiones. El editor no requiere administrador.
Git debe estar en el PATH para las funciones Git. Node es necesario para los
servidores y herramientas JavaScript (también Pyright); Python 3 para debugpy
y el lanzador jdtls. El módulo debugpy viene incluido, sin instalarlo en tu Python.
Tree-sitter CLI y un compilador C solo hacen falta para compilar parsers nuevos;
los parsers incluidos ya están compilados. El editor abre aunque falten estas
dependencias y `Comprobar.cmd` informa lo disponible.

1. Extraé **todo** el ZIP; no ejecutes archivos desde dentro del ZIP.
2. Copiá la carpeta a tu USB o al disco de la PC.
3. Abrí `Hilvim.cmd`. `Comprobar.cmd` verifica las herramientas incluidas.
4. Si querés dejarlo en esa PC, ejecutá `Instalar-en-esta-PC.cmd`: copia una
   versión limpia a tu usuario y crea un acceso directo sin administrador.

Desde una terminal también podés pasarle un proyecto:

```powershell
.\Hilvim.cmd C:\ruta\a\mi-proyecto
```

El lanzador aísla configuración, datos, caché y temporales en su carpeta.
Conserva el PATH del equipo, JAVA_HOME, .NET y los entornos virtuales.
No altera el PATH global ni la configuración de Neovim del equipo.
Los plugins ya vienen incluidos; el editor funciona sin Internet. Descargar
dependencias de proyectos o usar Copilot/Git remoto sí requiere red.
No se incluyen credenciales, entornos de proyectos, workloads Android/iOS,
Visual Studio ni Ant. Para C#, el Roslyn incluido requiere **runtime .NET 10**
en el equipo, además del SDK que use tu proyecto; un SDK 8/9 no satisface esa
dependencia. Java necesita un JDK compatible con el jdtls incluido.
Si falta un lenguaje, el editor abre igual y `Comprobar.cmd` muestra lo disponible.
Copilot es opt-in en el portable: `$env:HILVIM_COPILOT='1'; .\Hilvim.cmd`,
seguido de `:Copilot auth` con tu propia cuenta. La completación local funciona
sin activarlo.
La PC debe permitir ejecutar programas y PowerShell; el paquete no elude
restricciones de la universidad. La fuente y el emulador de terminal los elige
esa PC; una Nerd Font mejora los iconos, pero no es obligatoria para editar.

Después del uso, `user`, `state` y `cache` pueden contener información personal
o tokens. Para compartir, usá el ZIP original limpio, no una copia ya usada.
Para mejor rendimiento, copiá la carpeta desde la USB al disco local.

Para reconstruirlo en la PC preparada con Hilvim:

```powershell
.\scripts\build-portable.ps1 -Zip
# Retomar una construcción interrumpida en la misma carpeta:
.\scripts\build-portable.ps1 -Resume -Zip
# Reusar un ZIP Editor verificado con el mismo lazy-lock, sin recopia de apps:
python scripts\repack-editor.py dist\Hilvim-Portable-Editor.zip dist\Hilvim-Portable-Editor-1.2.zip --extract
# Opcional: paquete completo con SDKs/runtimes, JDK y GCC (mucho mas pesado):
.\scripts\build-portable.ps1 -FullToolchains -OutputPath dist\Hilvim-Full -Zip -JdkPath C:\ruta\al\openjdk
```

El constructor verifica las descargas, rutas portables, parsers, completación
nativa sin Git y handshake de los depuradores disponibles (Python requiere
intérprete del host). El perfil completo agrega
pruebas de compilación C/Java/C# y LSP Python. Necesita las herramientas que
empaqueta instaladas en la PC de construcción, espacio en disco y red para
descargas pendientes.
Los binarios generados se excluyen de Git; el código del constructor sí se versiona.

## Instalación convencional en Windows

Necesitás conexión a Internet, PowerShell 5.1 o posterior y
[Winget](https://learn.microsoft.com/windows/package-manager/winget/).
Descargá este repositorio o clonalo si ya tenés Git:

```powershell
git clone https://github.com/Hilvvy/nvim-config.git hilvim
cd hilvim
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

El instalador instala únicamente las herramientas que no encuentra en PATH:
Git, Neovim, ripgrep, fd, Tree-sitter CLI, GCC, Lazygit, Node.js LTS, Python,
Java JDK y .NET SDK. Winget puede solicitar elevación para algunos paquetes.
Si tu Neovim existente es anterior a 0.12, actualizalo antes de continuar.

Luego copia la configuración a `%LOCALAPPDATA%\nvim`, descarga el paquete
oficial de Roslyn 5.12.0-1.26426.8 desde NuGet a `nvim-data\tools`, restaura
los plugins de `lazy-lock.json` e instala los servidores, depuradores y parsers.
No uses `:MasonInstall roslyn`: Hilvim usa su paquete oficial local.

Si ya existe otra configuración, el instalador se detiene. Para conservarla
como `nvim.backup-FECHA-ID` e instalar Hilvim:

```powershell
.\install.ps1 -BackupExisting
```

Si ejecutás el script desde la propia configuración instalada, no la copia ni
la mueve. Los datos y plugins existentes en `nvim-data` se conservan.
Para volver a tu configuración anterior, cerrá Neovim, apartá la carpeta
actual `nvim` y renombrá el respaldo a `nvim`; no hace falta borrar los datos.

Opciones de instalación:

```powershell
.\install.ps1 -Check                 # Revisar herramientas, sin instalar
.\install.ps1 -SkipDependencies      # Usar herramientas ya instaladas
.\install.ps1 -SkipBootstrap         # No descargar plugins ni herramientas Mason
.\install.ps1 -SkipRoslyn            # Omitir descarga de Roslyn
```

`-ConfigPath` y `-DataPath` permiten preparar copias en rutas alternativas;
requieren `-SkipBootstrap`. `-SkipRoslyn` no habilita C# en una máquina nueva.
El instalador no modifica la terminal, su fuente ni la configuración de Windows.
Las descargas temporales de Roslyn quedan en `%TEMP%\hilvim-roslyn-*`.

Después abrí una terminal nueva y ejecutá `nvim`. Elegí una Nerd Font en la
terminal (por ejemplo Iosevka Nerd Font Mono) para los iconos y el dibujo.
Copilot requiere autenticación propia; no se copian credenciales.
La primera instalación puede tardar varios minutos.

## Atajos

`<leader>` es la barra espaciadora.

| Teclas | Acción |
| --- | --- |
| `Ctrl-p` | Buscar archivos con Telescope |
| `<leader>fg` / `<leader>fb` | Buscar texto / buffers |
| `<leader>e` | Explorador de archivos |
| `<leader>gg` | Lazygit en la raíz del proyecto |
| `<leader>ghp` | Vista previa de un cambio Git |
| `<leader>ut` | Alternar transparencia |
| `F5` | Iniciar o continuar depuración |
| `F10` / `F11` / `F12` | Step over / into / out |

En Lazygit, seleccioná un archivo con conflicto y pulsá `Enter` para resolverlo;
`Espacio` conserva el bloque seleccionado. Revisá el resultado antes del commit.
Para C#, compilá primero tu proyecto y elegí la DLL de `bin/Debug`; en attach,
seleccioná el proceso de la aplicación, no el de restore/build.
Python busca `.venv` o `venv`; instalá las dependencias del proyecto allí.
Java usa jdtls; los atajos Ant requieren tener Ant instalado por separado.

## Personalizar

- `asciiart.txt`: dibujo del dashboard; acepta las líneas de triple backtick.
  Conservá sus espacios y guardalo en UTF-8. Debajo aparece `hilvim /`.
- `lua/plugins/appearance.lua`: paleta Vague, modos de la barra y ventanas.
- `lua/plugins/snacks.lua`: dashboard, explorador y buscadores.
- `lua/config/options.lua`: opciones generales.

Con `<leader>ut`, tanto el editor como las ventanas flotantes alternan su fondo.
El blur depende de la terminal y del sistema operativo; Hilvim no lo configura.

## Comprobar y mantener

Comprobación automatizada de arranque, paleta, dashboard y herramientas:

```powershell
nvim --headless -i NONE -c "luafile scripts/check.lua"
.\scripts\test-install.ps1
```

Las pruebas deben terminar con `HILVIM_CHECK_OK` e `INSTALLER_CHECK_OK`.
La segunda usa carpetas temporales para verificar copia, respaldo y rechazo de
sobrescrituras; el rechazo intencional muestra un error durante la prueba.
Para revisar cada integración en el editor:

```vim
:checkhealth
:LspInfo
:Mason
:Lazy
```

En un proyecto C#, `:LspInfo` debe mostrar `roslyn`, no OmniSharp.
Para investigar DAP: `:lua require('dap').set_log_level('TRACE')` y `:DapShowLog`.
Para reinstalar las herramientas de desarrollo:

```powershell
.\install.ps1 -SkipDependencies
```

Si aparece `E138` al cerrar, ejecutá `:ShadaCleanup`. Solo limpia temporales
ShaDa vacíos con más de una hora. Al iniciar se limpian los mayores de un día.
Las notas de sesión en `.codex/` son locales y no se distribuyen.
