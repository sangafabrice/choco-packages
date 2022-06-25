$UpdateInfo = [PSCustomObject] @{
    Version  = '102.1.17189.115'
    Link     = 'https://browser-update.avast.com/browser/win/x86/102.1.17189.115/AvastBrowserInstaller.exe'
    Checksum = 'F9023B00E3B0A7E827A74995751C89675D2A3B54770F19EA715A56A95691B26E'
}
$UpdateInfo64 = [PSCustomObject] @{
    Version  = '102.1.17190.115'
    Link     = 'https://browser-update.avast.com/browser/win/x64/102.1.17190.115/AvastBrowserInstaller.exe'
    Checksum = 'C233DE64AF54D3DE82E2AB5A7858D0F38FFDAC173A511909EB8DA129EB55EC11'
}

## Current Install Helper Functions and Variables

$Name = 'Avast Secure Browser*'

$ShimName = 'AvastBrowser'

$OSArch = $(If ($(
	Try { (Get-WmiObject Win32_OperatingSystem).OSArchitecture -match '64' }
	Catch { [Environment]::Is64BitOperatingSystem }
)) { 'x64' } Else { 'x86' })

Filter Get-Executable {
	("$((Get-UninstallRegistryKey -SoftwareName $Name).InstallLocation)\$($ShimName).exe" |
	Get-Item -ErrorAction SilentlyContinue).FullName
}

$ExecutableType = (& {
	Switch (Get-Executable) {
		{ ![string]::IsNullOrEmpty($_) } {
			$PEHeaderOffset = New-Object Byte[] 2
			$PESignature = New-Object Byte[] 4
			$MachineType = New-Object Byte[] 2
			$FileStream = New-Object System.IO.FileStream -ArgumentList $_,'Open','Read','ReadWrite'
			$FileStream.Position = 0x3c
			[void] $FileStream.Read($PEHeaderOffset, 0, 2)
			$FileStream.Position = [System.BitConverter]::ToUInt16($PEHeaderOffset, 0)
			[void] $FileStream.Read($PESignature, 0, 4)
			[void] $FileStream.Read($MachineType, 0, 2)
			Switch ([System.BitConverter]::ToUInt16($MachineType, 0)){
				0x8664  { 'x64' }
				0x14c   { 'x86' }
				Default { $OSArch }
			}
			$FileStream.Close()
		}
		Default { $OSArch }
	}
})

Filter Get-Version {
	[version] $(Switch (Get-Executable) {
		{ ![string]::IsNullOrEmpty($_) } { (Get-ItemProperty ($_)).VersionInfo.ProductVersion }
		Default { '0.0.0.0' }
	})
}

Filter Test-IsOutdated {
	Param([version] $OpVersion)
	(Get-Version) -lt $OpVersion 
}

Filter Get-SilentUninstallString {
	(Get-UninstallRegistryKey -SoftwareName $Name).UninstallString |
	ForEach-Object { If (![string]::IsNullOrEmpty($_)) { ". $_ --force-uninstall" } }
}

Filter Stop-ExeProcess { 
	Get-Process $ShimName -ErrorAction SilentlyContinue | 
	Stop-Process -Force
}

Function Get-UpdateInfo {
	Try {
		Switch (
			Get-DownloadInfo -PropertyList @{
				UpdateServiceURL = 'https://update.avastbrowser.com/service/update2'
				ApplicationID    = '{A8504530-742B-42BC-895D-2BAD6406F698}'
				OwnerBrand       = '2101'
				OSArch           = $ExecutableType
			} -From Omaha
		) { { $Null -notin @($_.Version,$_.Link,$_.Checksum) } {
			$_.Link = "$($_.Link)"
			Return $_
		} }
		Throw
	}
	Catch { Switch ($ExecutableType) { 'x64' { $UpdateInfo64 } Default { $UpdateInfo } } }
}
