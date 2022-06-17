Class _ {
    Static [string] FormatXml([xml] $Xml, [uint] $Indent = 2) {
        $StringWriter = [System.IO.StringWriter]::New()
        $XmlWriter = [System.XMl.XmlTextWriter]::New($StringWriter)
        $XmlWriter.Formatting = "indented"
        $XmlWriter.Indentation = $Indent
        $Xml.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        Return $StringWriter.ToString()
    }
}

Filter New-TestSandbox {
    Push-Location $PSScriptRoot
    [xml] (Get-Content .\config.wsb -Raw) |
    ForEach-Object {
        $_.Configuration.MappedFolders.MappedFolder |
        ForEach-Object {
            $Folder = $_
            $ChocoPackages = (Get-Item $PSScriptRoot).Parent.FullName
            Switch ($_.SandboxFolder) {
                {$_ -match '\\dist$'} { $Folder.HostFolder = "$ChocoPackages\dist" }
                {$_ -match '\\test$'} { $Folder.HostFolder = "$ChocoPackages\main\test" }
            }
        }
        [_]::FormatXml($_, 4) | Out-File .\choco.wsb
    }
    Pop-Location
}

Filter Enable-WindowsSanbox {
    Try {
        'Microsoft-Hyper-V','Containers-DisposableClientVM' | 
        Select-Object @{
            Name = 'FeatureName';
            Expression = { $_ }
        } | Get-WindowsOptionalFeature -Online |
        Where-Object State -EQ Disabled |
        Enable-WindowsOptionalFeature -Online -All
    }
    Catch { "ERROR: $($_.Exception.Message)" }
}

Filter Start-TestSandbox { Start-Process "$PSScriptRoot\choco.wsb" }