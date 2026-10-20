@echo off
if not exist "%HILVIM_ROOT%\tools\python\python.exe" goto host
"%HILVIM_ROOT%\tools\python\python.exe" -I "%HILVIM_ROOT%\data\nvim-data\mason\packages\jdtls\bin\jdtls" %*
exit /b %errorlevel%
:host
python -I "%HILVIM_ROOT%\data\nvim-data\mason\packages\jdtls\bin\jdtls" %*
