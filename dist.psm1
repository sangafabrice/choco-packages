Class Distribution {
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
        $DIModule = Get-Module | Where-Object Name -eq 'DownloadInfo'
        Import-Module .\DownloadInfo -Force
        $GetXmlContent = { [xml] (Get-Content .\pkg.xml -Raw) }
        $PkgXml = & $GetXmlContent
        @{
            Current = [version] $PkgXml.package.version
            Download = [version] (Get-DownloadInfo -PropertyList @{
                    UpdateServiceURL = 'https://update.avastbrowser.com/service/update2'
                    ApplicationID    = '{A8504530-742B-42BC-895D-2BAD6406F698}'
                    OwnerBrand       = '2101'
                } -From Omaha).Version
        } | ForEach-Object {
            If ($_.Current -lt $_.Download) {
                $PkgXml.package.version = "$($_.Download)"
                $PkgXml.OuterXml | Out-File .\pkg.xml
            }
        }
        $Result = (& $GetXmlContent).package.version
        Remove-Module DownloadInfo -Force
        If ($DIModule.Count -gt 0) { Import-Module DownloadInfo }
        Pop-Location
        Return $Result
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