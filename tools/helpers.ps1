$UpdateInfo = [PSCustomObject] @{
    Version  = '4.25.2'
    Link     = 'https://github.com/mikefarah/yq/releases/download/v4.25.2/yq_windows_386.exe'
    Checksum = 'cbb4b89afbf42083b7c0f0576d88e35cf88e9cf926ffe06babe1e655bd41c64c2ef077eed22bdc7c8d3a081dcc4f26213305b9c408c77f98ce9caa48fbb676b1'
}
$UpdateInfo64 = [PSCustomObject] @{
    Version  = '4.25.2'
    Link     = 'https://github.com/mikefarah/yq/releases/download/v4.25.2/yq_windows_amd64.exe'
    Checksum = 'f55f9b4030a99fa2e3d5d08931b1213056c0597a41cedd58c379f3455a79c72cdd5db36ee653b5dbec952c4c5f5e86ae5ec68dd4befd5f1beb693f8e83c20702'
}

## Current Install Helper Functions and Variables

$Executable = "${Env:ChocolateyInstall}\bin\yq.exe"

$OSArch = $(If ($(
	Try { (Get-WmiObject Win32_OperatingSystem).OSArchitecture -match '64' }
	Catch { [Environment]::Is64BitOperatingSystem }
)) { 'x64' } Else { 'x86' })

Filter Get-Executable { (Get-Item $Executable -ErrorAction SilentlyContinue).FullName }

Filter Get-Version {
	[version] $(Switch (Get-Executable) {
		{ ![string]::IsNullOrEmpty($_) } { ((. $_ --version) -split ' ')[-1] }
		Default { '0.0.0.0' }
	})
}

Filter Test-IsOutdated {
	Param([version] $OpVersion)
	(Get-Version) -lt $OpVersion 
}

Function Get-UpdateInfo {
	Try {
		$ExeName = "yq_windows_$(Switch ($OSArch) { 'x64' { 'amd64' } Default { '386' } }).exe"
		Switch (
			Get-DownloadInfo -PropertyList @{
				RepositoryId = 'mikefarah/yq'
				AssetPattern = "$ExeName$|checksums.*$"
			}
		) { { $Null -notin @($_.Version,$_.Link) } {
			$SelectLink = {
				Param($Obj, $FileName)
				$Obj.Link.Url.Where({ "$Obj" -like "*$FileName" })
			}
			$RqstContent = {
				Param($Obj, $FileName)
				((Invoke-WebRequest "$(& $SelectLink $Obj $FileName)").Content |
				ForEach-Object { [char] $_ }) -join '' -split "`n"
			}
			$ShaIndex = "P$([array]::IndexOf((& $RqstContent $_ 'checksums_hashes_order'),'SHA-512') + 2)"
			Return [PSCustomObject] @{
				Version = $_.Version.Substring(1)
				Link = & $SelectLink $_ $ExeName
				Checksum = $(& $RqstContent $_ 'checksums' | ConvertFrom-String |
					Select-Object P1,$ShaIndex |
					Where-Object P1 -Like $ExeName).$ShaIndex
			}
		} }
		Throw
	}
	Catch { Switch ($OSArch) { 'x64' { $UpdateInfo64 } Default { $UpdateInfo } } }
}
