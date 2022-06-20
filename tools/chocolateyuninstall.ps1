$ErrorActionPreference = 'Stop'
. "$(Split-Path $MyInvocation.MyCommand.Definition)\helpers.ps1"
Switch (Get-SilentUninstallString) {
    { [string]::IsNullOrEmpty($_) } { 
        Write-Warning 'Google Chrome is already uninstalled.'
    }
	Default {
        Stop-ExeProcess
        Uninstall-BinFile -Name $ShimName
        Invoke-Expression $_
        Set-PowerShellExitCode -ExitCode 0
    }
}