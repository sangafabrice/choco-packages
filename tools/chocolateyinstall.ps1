$ErrorActionPreference = 'Stop'
$Private:ToolDir = Split-Path $MyInvocation.MyCommand.Definition
. "$ToolDir\helpers.ps1"
@{
	PackageName   = $Env:ChocolateyPackageName
	FileFullPath  = $Executable
} + (
	Get-UpdateInfo |
	ForEach-Object {
		@{
			Url          = $_.Link
			Checksum     = $_.Checksum
			ChecksumType = 'SHA512'
			Version      = $_.Version
		}
	}
) | ForEach-Object {
	If (Test-IsOutdated ([version] $_.Version)) {
		$_.Remove('Version')
		Get-ChocolateyWebFile @_
	}
}