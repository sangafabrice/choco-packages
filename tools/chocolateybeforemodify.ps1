$ErrorActionPreference = 'SilentlyContinue'
. "$PSScriptRoot\helper.ps1"
Get-Item ([CurrentInstall]::Executable()) |
Select-Object -Property @{
    Name = 'Name'
    Expression = { $_.Name -replace '\.exe$' }
} | Get-Process | Stop-Process -Force