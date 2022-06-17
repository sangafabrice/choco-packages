Class _ {
    Static [psobject] PushToDist([scriptblock] $ScriptBlock) {
        Push-Location '~\Desktop\dist'
        $Result = & $ScriptBlock
        Pop-Location
        Return $Result
    }
}

Filter Get-Package { [_]::PushToDist({ (Get-Item ".\*.nuspec").Name -replace '\.nuspec$' }) }

Filter Test-Install { [_]::PushToDist({ choco install (Get-Package) --source "'.;https://community.chocolatey.org/api/v2/'" --yes --force }) }

Filter Test-Upgrade { choco upgrade (Get-Package) --yes --force }

Filter Test-Uninstall { choco uninstall (Get-Package) --yes --force }