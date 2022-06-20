$UpdateInfo = @{
    Version  = '2021.12.17'
    Link     = 'https://github.com/ytdl-org/youtube-dl/releases/download/2021.12.17/youtube-dl.exe'
    Checksum = '24cc5ad86c35f40ff8f864f7098ebf50a0a57375216732b4e27a3fffa5de7dbe0f40bd41005e53fe1b2f0713df3f00182b8b552a785ccc41ee968144fe03075c'
}

## Current Install Helper Functions and Variables

$Executable = "${Env:ChocolateyInstall}\bin\youtube-dl.exe"

Filter Get-Executable { (Get-Item $Executable -ErrorAction SilentlyContinue).FullName }

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

Function Get-UpdateInfo {
	Try {
		Switch (
			Get-DownloadInfo -PropertyList @{
				RepositoryId = 'ytdl-org/youtube-dl'
        		AssetPattern = 'youtube-dl.exe$|SHA2-512SUMS$'
			}
		) { { $Null -notin @($_.Version,$_.Link) } { 
			Return [PSCustomObject] @{
				Version  = $_.Version
				Link     = $_.Link.Where({$_.Url -like '*.exe'}).Url
				Checksum = (((Invoke-WebRequest "$($_.Link.Where({$_.Url -like '*512SUMS'}).Url)").Content |
					ForEach-Object { [char] $_ }) -join '' -split "`n" |
					ConvertFrom-String).Where({$_.P2 -ieq 'youtube-dl.exe'}).P1
			}
		} }
		Throw
	}
	Catch { $UpdateInfo }
}
