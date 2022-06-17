Class Distribution {
    Static [string] $PackageName = ((Get-Item "$(& { $PSScriptRoot })\*.nuspec").Name -replace '\.nuspec$')
    
    Static [string] NewNugetPackage($Version, [string] $Properties) {
        Push-Location $PSScriptRoot
        $Result = $(& {
            Try {
                If ($Version -is [scriptblock]) { $Version = & $Version }
                Invoke-Expression "choco pack --version=$Version $Properties" > $Null 2>&1
                If ($LASTEXITCODE -eq 1) { Throw }
                Return "$([Distribution]::PackageName).$Version.nupkg"
            }
            Catch { }
        })
        Pop-Location
        Return $Result
    }
}

Filter New-Package {
    <#
    .SYNOPSIS
        Create a nuget package
    .NOTES
        Precondition:
        1. choco must be installed
    #>
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
        If ((where.exe choco.exe).Count -eq 0) { Throw 'ChocoNotFoundOnPath' }
        choco apikey --key $Env:CHOCO_API_KEY --source https://push.chocolatey.org/
        choco push $NugetPackage --source https://push.chocolatey.org/
    }
    Catch { "ERROR: $($_.Exception.Message)" }
}

Filter Deploy-Package {
    <#
    .SYNOPSIS
        Run deployment tasks
    #>

    Push-Location $PSScriptRoot
    Try {

    }
    Catch { "ERROR: $($_.Exception.Message)" }
    Pop-Location
}