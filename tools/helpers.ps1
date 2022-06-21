$UpdateInfo = @{
    Version = '102.0.16815.63'
    Link = 'https://browser-update.avast.com/browser/win/x86/102.0.16815.63/AvastBrowserInstaller.exe'
    Checksum = '7EE73EF78AACDA80763A22B5FD552EDB17B9EDA58A83014072806DBD7290ACD1'
}
$UpdateInfo64 = @{
    Version = '102.0.16817.63'
    Link = 'https://browser-update.avast.com/browser/win/x64/102.0.16817.63/AvastBrowserInstaller.exe'
    Checksum = 'BED8A807BD4E9BDD9F29AA91C93580AFDCBED7ABC35250BF6766825998F98726'
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
