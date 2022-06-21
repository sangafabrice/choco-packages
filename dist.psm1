Import-Module "$PSScriptRoot\DownloadInfo" -Force

Class Distribution {
    Static [hashtable] $PropertyList = @{
        RepositoryId = 'ytdl-org/youtube-dl'
        AssetPattern = 'youtube-dl.exe$|SHA2-512SUMS$'
    }

    Static $UpdateInfo32 = $(Get-DownloadInfo -PropertyList ([Distribution]::PropertyList))

    Static [string] $PackageName = ((Get-Item "$(& { $PSScriptRoot })\*.nuspec").Name -replace '\.nuspec$')
    
    Static [string] NewNugetPackage($Version, [string] $Properties) {
        Push-Location $PSScriptRoot
        $Result = $(& {
            Try {
                If ($Version -is [scriptblock]) { $Version = & $Version }
                If ($Version -notmatch '^[0-9]+(\.[0-9]+){2}$') { Throw }
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
            Current  = [version] $PkgXml.package.version
            Download = [version] ([Distribution]::UpdateInfo32).Version
        } | ForEach-Object {
            If ($_.Current -le $_.Download) {
                $PkgXml.package.version = "$($_.Download)"
                $PkgXml.OuterXml | Out-File .\pkg.xml
                '.\tools\helpers.ps1' |
                ForEach-Object {
                    $Dui = [Distribution]::UpdateInfo()
                    $Count = (Get-Content $_ |
                    Select-Object -Skip ($Dui -split "`n").Count).Count
                    Set-Content $_ -Value ($Dui + "`n" + ((Get-Content $_ -Tail $Count) -join "`n"))
                }
            }
        }
        $Result = (& $GetXmlContent).package.version
        Pop-Location
        Return $Result
    }

    Static [string] SelectLink($Link) { Return $Link.Where({$_.Url -like '*.exe'}).Url }

    Static [string] SelectChecksum($Link) { 
        Return (
            (((Invoke-WebRequest "$($Link.Where({$_.Url -like '*512SUMS'}).Url)").Content |
            ForEach-Object { [char] $_ }) -join '' -split "`n" |
            ConvertFrom-String).Where({$_.P2 -ieq 'youtube-dl.exe'}).P1
        )
    }

    Static [string] UpdateInfo() {
        $UI32 = [Distribution]::UpdateInfo32
        Return @"
`$UpdateInfo = [PSCustomObject] @{
    Version  = '$($UI32.Version)'
    Link     = '$([Distribution]::SelectLink($UI32.Link))'
    Checksum = '$([Distribution]::SelectChecksum($UI32.Link))'
}
"@
    }
}

Filter New-Package {
    <#
    .SYNOPSIS
        Create a nuget package
    #>

    [Distribution]::UpdateVersion() |
    ForEach-Object { [Distribution]::NewNugetPackage($_, "year=$((Get-Date).Year) version=$_") }
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