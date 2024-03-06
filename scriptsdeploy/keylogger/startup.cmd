rem cmd-file to run logger-automatically on startup
rem place in "C:\Users\<USER>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
rem changes the Execution-Policy
rem Execution-Policy already has to be enabled in order to run

@echo off
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

echo Running PowerShell script...

rem Change this to match the location of the script on your machine
powershell -File "%USERPROFILE%\Desktop\bachelor\powershell\2Logger.ps1"

echo Script executed successfully.
exit /b 0
