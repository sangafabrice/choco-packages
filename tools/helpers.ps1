$UpdateInfo = @{
    Version  = '102.0.5005.115'
    Link     = 'https://edgedl.me.gvt1.com/edgedl/release2/chrome/adc3ziyugsggp3yfi4baggeg6osq_102.0.5005.115/102.0.5005.115_chrome_installer.exe'
    Checksum = 'B45C5ECE01DC24253938B02775612ECCC4F8ABDF3E4A089D4355D73756F82A57'
}
$UpdateInfo64 = @{
    Version  = '102.0.5005.115'
    Link     = 'https://edgedl.me.gvt1.com/edgedl/release2/chrome/aceomm4bgo4gjd56jq2ebspjaama_102.0.5005.115/102.0.5005.115_chrome_installer.exe'
    Checksum = '0E6C7AF39B7BDDA56B7AC5E2E0CFD344E891A1B2D69F042662EE15AE36C2FB9F'
}

## Current Install Helper Functions and Variables

$Name = 'Google Chrome*'

$ShimName = 'chrome'

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
				UpdateServiceURL = 'https://update.googleapis.com/service/update2'
				ApplicationID    = '{8A69D345-D564-463c-AFF1-A69D9E530F96}'
				OwnerBrand       = "$(Switch ($ExecutableType) { 'x64' { 'YTUH' } Default { 'GGLS' } })"
				ApplicationSpec  = "$(Switch ($ExecutableType) { 'x64' { 'x64-stable-statsdef_1' } Default { 'stable-arch_x86-statsdef_1' } })"
			} -From Omaha
		) { { $Null -notin @($_.Version,$_.Link,$_.Checksum) } {
			$_.Link = "$($_.Link.Where({ "$_" -like 'https://*' })[0])"
			Return $_
		} }
		Throw
	}
	Catch { Switch ($ExecutableType) { 'x64' { $UpdateInfo64 } Default { $UpdateInfo } } }
}
