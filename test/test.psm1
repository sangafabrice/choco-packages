$PushToDist = {
    Param ([scriptblock] $ScriptBlock = {})
    Push-Location '~\Desktop\dist'
    & $ScriptBlock
    Pop-Location
}

Filter Get-Package { & $PushToDist { (Get-Item ".\*.nuspec").Name -replace '\.nuspec$' } }

Filter Test-Install { & $PushToDist { choco install (Get-Package) --source "'.;https://community.chocolatey.org/api/v2/'" --yes --force } }

Filter Test-Upgrade { choco upgrade (Get-Package) --yes --force }

Filter Test-Uninstall { choco uninstall (Get-Package) --yes --force }

Export-ModuleMember -Function '*'