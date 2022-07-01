$UpdateInfo = [PSCustomObject] @{
    Version  = '4.25.3'
    Link     = 'https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_windows_386.exe'
    Checksum = 'e7a0ebd6c8eb207d2fab444291df032f4a936fd19d3079b49106862643dcefa397617a3bc692b596463e352847a8106e9551945cf20483581846a747c7b5c7b2'
}
$UpdateInfo64 = [PSCustomObject] @{
    Version  = '4.25.3'
    Link     = 'https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_windows_amd64.exe'
    Checksum = '70344bf81bcdfa4e372242133cf37e6ca0a3b7056c604354d021f751ad59bbe8771c5bbd97207a2894e94f3db79e262fa8cb91c83fe61a033966a21e75684fb9'
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
				$Obj.Link.Url.Where({ "$_" -like "*$FileName" })
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
