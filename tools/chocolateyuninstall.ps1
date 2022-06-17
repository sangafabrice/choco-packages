$ErrorActionPreference = 'Stop';
. "$PSScriptRoot\helper.ps1"
Switch ([CurrentInstall]::SilentUninstallString()) {
    { [string]::IsNullOrEmpty($_) } { Write-Warning 'Avast Secure Browser is already uninstalled.' }
	Default { Invoke-Expression ". $([CurrentInstall]::SilentUninstallString())" }
}