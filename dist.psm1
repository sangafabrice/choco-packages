Import-Module "$PSScriptRoot\DownloadInfo" -Force

Class Distribution {
    Static [hashtable] $PropertyList = @{
        UpdateServiceURL = 'https://update.avastbrowser.com/service/update2'
        ApplicationID    = '{A8504530-742B-42BC-895D-2BAD6406F698}'
        OwnerBrand       = '2101'
    }

    Static [hashtable] $PtyList32 = $(([Distribution]::PropertyList) + @{ OSArch = 'x86' })

    Static [hashtable] $PtyList64 = $(([Distribution]::PropertyList) + @{ OSArch = 'x64' })

    Static $UpdateInfo32 = $(Get-DownloadInfo -PropertyList ([Distribution]::PtyList32) -From Omaha)

    Static $UpdateInfo64 = $(Get-DownloadInfo -PropertyList ([Distribution]::PtyList64) -From Omaha)

    Static [string] $PackageName = ((Get-Item "$(& { $PSScriptRoot })\*.nuspec").Name -replace '\.nuspec$')
    
    Static [string] NewNugetPackage($Version, [string] $Properties) {
        Push-Location $PSScriptRoot
        $Result = $(& {
            Try {
                If ($Version -is [scriptblock]) { $Version = & $Version }
                If ($Version -notmatch '^[0-9]+(\.[0-9]+){3}$') { Throw }
                Invoke-Expression "choco pack --version=$Version $Properties" > $Null 2>&1
                If ($LASTEXITCODE -eq 1) { Throw }
                Return "$([Distribution]::PackageName).$Version.nupkg"
            }
            Catch { }
        })
        Pop-Location
        Return $Result
    }

    Static [string] UpdateVersion() {
        Push-Location $PSScriptRoot
        $GetXmlContent = { [xml] (Get-Content .\pkg.xml -Raw) }
        $PkgXml = & $GetXmlContent
        @{
            Current = [version] $PkgXml.package.version
            Current32 = [version] $PkgXml.package.version32
            Download = [version] ([Distribution]::UpdateInfo64).Version
            Download32 = [version] ([Distribution]::UpdateInfo32).Version
        } | ForEach-Object {
            If ($_.Current -le $_.Download -and $_.Current32 -le $_.Download32) {
                $PkgXml.package.version = "$($_.Download)"
                $PkgXml.package.version32 = "$($_.Download32)"
                $PkgXml.OuterXml | Out-File .\pkg.xml
                '.\tools\helpers.ps1' |
                ForEach-Object {
                    $Count = (Get-Content $_ |
                    Select-Object -Skip ([Distribution]::UpdateInfo() -split "`n").Count).Count
                    Set-Content $_ -Value ([Distribution]::UpdateInfo() + "`n" + ((Get-Content $_ -Tail $Count) -join "`n"))
                }
            }
        }
        $Result = (& $GetXmlContent).package.version
        Pop-Location
        Return $Result
    }

    Static [string] UpdateInfo() {
        $UI32 = [Distribution]::UpdateInfo32
        $UI64 = [Distribution]::UpdateInfo64
        Return @"
`$UpdateInfo = @{
    Version  = '$($UI32.Version)'
    Link     = '$($UI32.Link)'
    Checksum = '$($UI32.Checksum)'
}
`$UpdateInfo64 = @{
    Version  = '$($UI64.Version)'
    Link     = '$($UI64.Link)'
    Checksum = '$($UI64.Checksum)'
}
"@
    }
}

Filter New-Package {
    <#
    .SYNOPSIS
        Create a nuget package
    #>

    [Distribution]::NewNugetPackage([Distribution]::UpdateVersion(), "year=$((Get-Date).Year)")
}

Filter Publish-Package {
    <#
    .SYNOPSIS
        Publish chocolatey package to Community repository
    .NOTES
        Precondition:
        1. The CHOCO_API_KEY environment variable is set.
    #>

    Param([Parameter(Mandatory=$true)] $NugetPackage)

    Try {
        If ($null -eq $Env:CHOCO_API_KEY) { Throw 'CHOCO_API_KEY_IsNull' }
        choco apikey --key $Env:CHOCO_API_KEY --source https://push.chocolatey.org/
        If ($LASTEXITCODE -eq 1) { Throw }
        choco push $NugetPackage --source https://push.chocolatey.org/
        If ($LASTEXITCODE -eq 1) { Throw }
    }
    Catch { "ERROR: $($_.Exception.Message)" }
}

Filter Deploy-Package {
    <#
    .SYNOPSIS
        Run deployment tasks
    #>

    Push-Location $PSScriptRoot
    New-Package |
    ForEach-Object {
        Publish-Package $_
        Remove-Item $_ -Force
    }
    Pop-Location
}