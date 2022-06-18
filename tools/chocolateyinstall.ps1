$ErrorActionPreference = 'Stop'
$Private:ToolDir = Split-Path $MyInvocation.MyCommand.Definition
. "$ToolDir\helpers.ps1"
@{
	PackageName   = $Env:ChocolateyPackageName
	UnzipLocation = $ToolDir
	FileType      = 'exe'
	SoftwareName  = $Name
	SilentArgs    = '--chrome --do-not-launch-chrome --hide-browser-override --show-developer-mode --suppress-first-run-bubbles --default-search-id=1001 --default-search=google.com --adblock-mode-default=1'
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