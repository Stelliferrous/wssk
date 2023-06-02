[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

function wingetDownload {
    $wingetreleaseUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $wingetreleaseInfo = Invoke-RestMethod -Uri $wingetreleaseUrl
    $wingetDResult = @{
        Success = $false
        Message = ""
        File = ""
    }
    if ($wingetreleaseInfo) {
        $latestReleaseTag = $wingetreleaseInfo.tag_name
        $assetUrl = ($wingetreleaseInfo.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url
        if ($assetUrl) {
            $wingetDResult.File = "lib\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe-$latestReleaseTag.msixbundle"
            if (-not (Test-Path -Path $wingetDResult.File)) {
                try {
                    Invoke-WebRequest -Uri $assetUrl -OutFile $wingetDResult.File
                    $wingetDResult.Success = $true
                    $wingetDResult.Message = "Downloaded $repo release $latestReleaseTag"
                } 
                catch {
                    $wingetDResult.Message = "Download Failed"
                }
            } else {
                $wingetDResult.Success = $true
                $wingetDResult.Message = "Already downloaded"
            }
        } else {
            $wingetDResult.Message =  "No .msixbundle asset found in the latest release of $repo"
        }
    } else {
        $wingetDResult.Message = "Failed to retrieve the latest release of $repo"
    }
    return $wingetDResult
}

function vclibsDownload {
    $vclibsDResult = @{
        Success = $false
        Message = ""
        File = ""
    }
    $vclibsFileName = "Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $vclibsUrl = "https://aka.ms/$vclibsFileName"
    $vclibsDResult.File = "lib\$vclibsFileName"
    
    if (!(Test-Path $vclibsDResult.File)) {
        try {
            Invoke-WebRequest -Uri $vclibsUrl -OutFile $vclibsDResult.File
            $vclibsDResult.Success = $true
            $vclibsDResult.Message = "Downloaded $repo release $latestReleaseTag"
        } 
        catch {
            $vclibsDResult.Message = "Failed to download VCLibs"
        }
    } else {
        $vclibsDResult.Success = $true
        $vclibsDResult.Message = "Already Downloaded"
    }
    return $vclibsDResult
}

function vclibsInstall {
    $vclibsResult = @{
        Success = $false
        Message = ""
    }
    $vclibsDownloadResults = vclibsDownload
    if ($vclibsDownloadResults.Success) {
        # Write-Host("Success: $($vclibsDownloadResults.Message)")
        try {
            Add-AppxPackage -Path $vclibsDownloadResults.File -ErrorAction Stop
            $vclibsResult.Success = $true
            $vclibsResult.Message = "VCLibs installation successful"
        }
        catch {
            $vclibsResult.Message = "VCLibs installation failed: $($_.Exception.Message)"
        }
    } else {
        $vclibsResult.Success = $false
        $vclibsResult.Message = $vclibsDownloadResults.Message
    }
    return $vclibsResult
}
function wingetInstall {
    $wingetResult = @{
        Success = $false
        Message = ""
    }
    $vclibsInstallResult = vclibsInstall
    if ($vclibsInstallResult.Success) {
        $wingetDownloadResults = wingetDownload
        if ($wingetDownloadResults.Success) {
            try {
                Add-AppxPackage -Path $wingetDownloadResults.File -ErrorAction Stop
                $wingetResult.Success = $true
                $wingetResult.Message = "winget installation successful"
            }
            catch {
                $wingetResult.Message = "winget installation failed: $($_.Exception.Message)"
            }
        } else {
            $wingetResult.Message = "Failed to install winget: $($wingetDownloadResults.Message)"
        }
    } else {
        $wingetResult.Message = "Failed to install winget: $($vclibsInstallResult.Message)"
    }
    return $wingetResult
}

function nugetInstall {
    $nugetResult = @{
        Success = $false
        Message = ""
    }
    if (!(Test-Path "C:\Users\WDAGUtilityAccount\AppData\Roaming\NuGet\nuget.config")) {
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
            $nugetResult.Success = $true
            $nugetResult.Message = "nuget installation successful"
        }
        catch {
            $nugetResult.Message = "nuget installation failed: $($_.Exception.Message)"
        }
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    } else {
        $nugetResult.Success = $true
        $nugetResult.Message = "nuget Already found"
    }
    return $nugetResult
}

function chocolateyInstall {
    $chocoResult = @{
        Success = $false
        Message = ""
    }
    if (!(Test-Path "C:\ProgramData\chocolately\choco.exe")) { #There is a better way to handle this #TODO
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $chocoResult.Success = $true
            $chocoResult.Message = "Installed chocolatey"
            choco feature enable -n allowGlobalConfirmation
        }
        catch {
            $chocoResult.Message = "Chocolatey install failed, Something something." #TODO
        }
    }
    return $chocoResult
}

function explorerRestart {
    Get-Process explorer | ForEach-Object {
        $_ | Stop-Process
        $_.WaitForExit(5000)
        if (-not $_.HasExited) {
            $_ | Stop-Process -Force
        }
    }
    Start-Process explorer
}

function registryEditor {
    param (
        [Parameter(Mandatory = $true)]
        [String]$regPath,
        [Parameter(Mandatory = $true)]
        [String]$regName,
        [Parameter(Mandatory = $true)]
        [String]$regValue,
        [Parameter(Mandatory = $false)]
        [Boolean]$restartExplorer = $false
    )
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath
    }
    Set-ItemProperty -Path $regPath -Name $regName -Value $regValue
    
}