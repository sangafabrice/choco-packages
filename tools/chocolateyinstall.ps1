$ErrorActionPreference = 'Stop'
$Private:ToolDir = Split-Path $MyInvocation.MyCommand.Definition
. "$ToolDir\helpers.ps1"
@{
	PackageName   = $Env:ChocolateyPackageName
	FileFullPath  = $Executable
} + (
	Get-UpdateInfo |
	ForEach-Object {
		$( If ($OSArch -eq 'x64') { @{
			Url64bit       = $_.Link
			Checksum64     = $_.Checksum
			ChecksumType64 = 'SHA512'
		} } Else { @{
			Url          = $_.Link
			Checksum     = $_.Checksum
			ChecksumType = 'SHA512'
		} } ) + @{ Version = $_.Version }
	}
) | ForEach-Object {
	If (Test-IsOutdated ([version] $_.Version)) {
		$_.Remove('Version')
		Get-ChocolateyWebFile @_
	}
}