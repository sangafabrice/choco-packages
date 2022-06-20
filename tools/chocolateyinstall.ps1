$ErrorActionPreference = 'Stop'
$Private:ToolDir = Split-Path $MyInvocation.MyCommand.Definition
. "$ToolDir\helpers.ps1"
@{
	PackageName   = $Env:ChocolateyPackageName
	UnzipLocation = $ToolDir
	FileType      = 'exe'
	SoftwareName  = $Name
	SilentArgs    = '--verbose-logging --do-not-launch-chrome --channel=stable'
} + (
	Get-UpdateInfo |
	ForEach-Object {
		$( If ($ExecutableType -eq 'x64') { @{
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
	If (Test-IsOutdated ([version] $_.Version)) {
		$_.Remove('Version')
		Stop-ExeProcess
		Install-ChocolateyPackage @_
	}
	Try {
		@{
			Name = $ShimName
			Path = (Get-Executable)
		} | ForEach-Object { Install-BinFile @_ } 
	}
	Catch { "ERROR: $($_.Exception.Message)" }
}