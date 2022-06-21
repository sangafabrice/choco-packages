$ErrorActionPreference = 'Stop'
. "$(Split-Path $MyInvocation.MyCommand.Definition)\helpers.ps1"
Try {
    Remove-Item $Executable -Force
    Set-PowerShellExitCode -ExitCode 0
}
Catch { Write-Warning 'YQ is already uninstalled.' }