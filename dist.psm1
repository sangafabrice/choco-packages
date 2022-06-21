Import-Module "$PSScriptRoot\DownloadInfo" -Force

Class Distribution {
    Static [hashtable] $PropertyList = @{
        RepositoryId = 'mikefarah/yq'
        AssetPattern = "yq_windows_amd64.exe$|yq_windows_386.exe$|checksums.*$"
    }

    Static $UpdateInfo_ = $(Get-DownloadInfo -PropertyList ([Distribution]::PropertyList))

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
            Current = [version] $PkgXml.package.version
            Download = [version] ([Distribution]::UpdateInfo_).Version.Substring(1)
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

    Static [string] SelectLink($Info, $FileName) { Return $Info.Link.Url.Where({ "$_" -like "*$FileName" }) }

    Static [string[]] GetRequestContent($Info, $FileName) {
        Return ((Invoke-WebRequest "$([Distribution]::SelectLink($Info, $FileName))").Content |
			ForEach-Object { [char] $_ }) -join '' -split "`n"
    }

    Static [string] SelectChecksum($Info, $ExeName) { 
        Return $(
            $ShaIndex = "P$([array]::IndexOf([Distribution]::GetRequestContent($Info, 'checksums_hashes_order'),'SHA-512') + 2)"
            ([Distribution]::GetRequestContent($Info, 'checksums') | ConvertFrom-String |
            Select-Object P1,$ShaIndex |
            Where-Object P1 -Like $ExeName).$ShaIndex
        )
    }

    Static [string] UpdateInfo() {
        $UI = [Distribution]::UpdateInfo_
        $VersionString = $UI.Version.Substring(1)
        Return @"
`$UpdateInfo = [PSCustomObject] @{
    Version  = '$VersionString'
    Link     = '$([Distribution]::SelectLink($UI, 'yq_windows_386.exe'))'
    Checksum = '$([Distribution]::SelectChecksum($UI, 'yq_windows_386.exe'))'
}
`$UpdateInfo64 = [PSCustomObject] @{
    Version  = '$VersionString'
    Link     = '$([Distribution]::SelectLink($UI, 'yq_windows_amd64.exe'))'
    Checksum = '$([Distribution]::SelectChecksum($UI, 'yq_windows_amd64.exe'))'
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