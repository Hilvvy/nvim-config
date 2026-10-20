@echo off
if not exist "%HILVIM_ROOT%\tools\python\python.exe" goto host
"%HILVIM_ROOT%\tools\python\python.exe" -I -m debugpy.adapter %*
exit /b %errorlevel%
:host
python -I "%HILVIM_ROOT%\scripts\debugpy-launcher.py" %*
