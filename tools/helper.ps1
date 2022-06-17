Class CurrentInstall {
	Static $Name = 'Avast Secure Browser*'

	Static $MachineType = $(
		$ExePath = [CurrentInstall]::Executable()
		If (![string]::IsNullOrEmpty($ExePath)) {
			$PEHeaderOffset = [Byte[]]::New(2)
			$PESignature = [Byte[]]::New(4)
			$MachineType = [Byte[]]::New(2)
			$FileStream = [System.IO.FileStream]::New($ExePath, 'Open', 'Read', 'ReadWrite')
			$FileStream.Position = 0x3c
			[void] $FileStream.Read($PEHeaderOffset, 0, 2)
			$FileStream.Position = [System.BitConverter]::ToUInt16($PEHeaderOffset, 0)
			[void] $FileStream.Read($PESignature, 0, 4)
			[void] $FileStream.Read($MachineType, 0, 2)
			Switch ([System.BitConverter]::ToUInt16($MachineType, 0)){
				0x8664 { 'x64' }
				0x14c  { 'x86' }
			}
			$FileStream.Close()
		} ElseIf ([Environment]::Is64BitOperatingSystem) { 'x64' } Else { 'x86' }
	)

	Static $Is64bit = $([CurrentInstall]::MachineType -eq 'x64')

	Static [version] Version() {
		$ExePath = [CurrentInstall]::Executable()
		Return [version] $(If (![string]::IsNullOrEmpty($ExePath)) {
			(Get-ItemProperty ($ExePath)).VersionInfo.ProductVersion
		} Else { '0.0.0.0' })
	}

	Static [bool] IsOutdated([version] $OpVersion) { Return [CurrentInstall]::Version() -lt $OpVersion }

	Static [string] Executable() {
		Return ("$((Get-UninstallRegistryKey -SoftwareName ([CurrentInstall]::Name)).InstallLocation)\AvastBrowser.exe" |
		Get-Item -ErrorAction SilentlyContinue).FullName
	}

	Static [string] SilentUninstallString() {
		Return (Get-UninstallRegistryKey -SoftwareName ([CurrentInstall]::Name)).UninstallString |
		ForEach-Object { If (![string]::IsNullOrEmpty($_)) { "$_ --force-uninstall" } }
	}
}