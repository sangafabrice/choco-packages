@Echo OFF
PushD "%USERPROFILE%\Desktop"
SetLocal
Powershell -Command "& { Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force }"
Powershell -Command "& { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) }"
:Loop
Rem
If Not EXIST %ProgramData%\Chocolatey GoTo Loop
Set Path=%ProgramData%\Chocolatey;%Path%
If /I '%USERNAME%' NEQ 'WDAGUtilityAccount' Set VersionAttribute=-Version 2.0
Start /Max Powershell %VersionAttribute% -NoExit -Command "Import-Module .\test -Prefix 'Choco'"
EndLocal
PopD