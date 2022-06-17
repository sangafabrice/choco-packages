$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\helper.ps1"
@{
	PackageName   = $Env:ChocolateyPackageName
	UnzipLocation = $PSScriptRoot
	FileType      = 'exe'
	SoftwareName  = [CurrentInstall]::Name
	SilentArgs    = '--chrome --do-not-launch-chrome --hide-browser-override --show-developer-mode --suppress-first-run-bubbles --default-search-id=1001 --default-search=google.com --adblock-mode-default=1'
} + (
	Get-DownloadInfo -PropertyList @{
		UpdateServiceURL = 'https://update.avastbrowser.com/service/update2'
		ApplicationID    = '{A8504530-742B-42BC-895D-2BAD6406F698}'
		OwnerBrand       = '2101'
		OSArch           = [CurrentInstall]::MachineType
	} -From Omaha | ForEach-Object {
		$( If ([CurrentInstall]::Is64bit) { @{
			Url64bit       = $_.Link
			Checksum64     = $_.Checksum
			ChecksumType64 = 'SHA256'
		} } Else { @{
			Url          = $_.Link
			Checksum     = $_.Checksum
			ChecksumType = 'SHA256'
		} } ) + @{ Version = $_.Version }
	}
) | ForEach-Object {
	If ([CurrentInstall]::IsOutdated([version] $_.Version)) {
		$_.Remove('Version')
		Install-ChocolateyPackage @_
	}
	Try {
		Get-Item ([CurrentInstall]::Executable()) |
		ForEach-Object { @{
			Name = $_.Name -replace '\.exe$'
			Path = $_.FullName
		} } | ForEach-Object { Install-BinFile @_ } 
	}
	Catch { "ERROR: $($_.Exception.Message)" }
}