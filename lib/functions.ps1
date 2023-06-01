[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

function wingetDownload {
    $wingetreleaseUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $wingetreleaseInfo = Invoke-RestMethod -Uri $wingetreleaseUrl
    $result = @{
        Success = $false
        Message = ""
        File = ""
    }
    if ($wingetreleaseInfo) {
        $latestReleaseTag = $wingetreleaseInfo.tag_name
        $assetUrl = ($wingetreleaseInfo.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url
        if ($assetUrl) {
            $result.File = "lib\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe-$latestReleaseTag.msixbundle"
            if (-not (Test-Path -Path $result.File)) {
                try {
                    Invoke-WebRequest -Uri $assetUrl -OutFile $result.File
                    $result.Success = $true
                    $result.Message = "Downloaded $repo release $latestReleaseTag"
                } 
                catch {
                    $result.Message = "Download Failed"
                }
            } else {
                $result.Success = $true
                $result.Message = "Already downloaded"
            }
        } else {
            $result.Message =  "No .msixbundle asset found in the latest release of $repo"
        }
    } else {
        $result.Message = "Failed to retrieve the latest release of $repo"
    }
    return $result
}

function vclibsDownload {
    $result = @{
        Success = $false
        Message = ""
        File = ""
    }
    $vclibsFileName = "Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $vclibsUrl = "https://aka.ms/$vclibsFileName"
    $result.File = "lib\$vclibsFileName"
    
    if (!(Test-Path $result.File)) {
        try {
            Invoke-WebRequest -Uri $vclibsUrl -OutFile $result.File
            $result.Success = $true
            $result.Message = "Downloaded $repo release $latestReleaseTag"
        } 
        catch {
            $result.Message = "Failed to download VCLibs"
        }
    } else {
        $result.Success = $true
        $result.Message = "Already Downloaded"
    }
    return $result
}

function vclibsInstall {
    $result = @{
        Success = $false
        Message = ""
    }
    $vclibsDownloadResults = vclibsDownload
    if ($vclibsDownloadResults.Success) {
        # Write-Host("Success: $($vclibsDownloadResults.Message)")
        try {
            Add-AppxPackage -Path $vclibsDownloadResults.File -ErrorAction Stop
            $result.Success = $true
            $result.Message = "VCLibs installation successful"
        }
        catch {
            $result.Message = "VCLibs installation failed: $($_.Exception.Message)"
        }
    } else {
        $result.Success = $false
        $result.Message = $vclibsDownloadResults.Message
        # Write-Host("Failed: $($vclibsDownloadResults.Message)")
    }
    return $result
}
function wingetInstall {
    $result = @{
        Success = $false
        Message = ""
    }
    $vclibsInstallResult = vclibsInstall
    if ($vclibsInstallResult.Success) {
        $wingetDownloadResults = wingetDownload
        if ($wingetDownloadResults.Success) {
            try {
                Add-AppxPackage -Path $wingetDownloadResults.File -ErrorAction Stop
                $result.Success = $true
                $result.Message = "winget installation successful"
            }
            catch {
                $result.Message = "winget installation failed: $($_.Exception.Message)"
            }
        } else {
            $result.Message = "Failed to install winget: $($wingetDownloadResults.Message)"
        }
    } else {
        $result.Message = "Failed to install winget: $($vclibsInstallResult.Message)"
    }
    return $result
}

function nugetInstall {
    $result = @{
        Success = $false
        Message = ""
    }
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
        $result.Success = $true
        $result.Message = "nuget installation successful"
    }
    catch {
        $result.Message = "nuget installation failed: $($_.Exception.Message)"
    }
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    return $result
}

function chocolateyInstall {
    $result = @{
        Success = $false
        Message = ""
    }
    $nugetInstallResults = nugetInstall
    if ($nugetInstallResults.Success) {
        if (!(Test-Path "C:\ProgramData\chocolately\choco.exe")) { #There is a better way to handle this TODO
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        if (Test-Path "C:\ProgramData\chocolately\choco.exe") {
            $result.Success = $true
            $result.Message = "Installed chocolatey"
            choco feature enable -n allowGlobalConfirmation
        } else {
            $result.Message = "Chocolatey install failed: $($_.Exception.Message)"
        }
    } else {
        $result.Message = "Failed chocolately install: $($nugetInstallResults.Message)"
    }
    
}
