
$savePath = "C:\Users\WDAGUtilityAccount\Documents\wssk\"
Set-Location $savePath

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

$wingetreleaseUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
$wingetreleaseInfo = Invoke-RestMethod -Uri $wingetreleaseUrl
if ($wingetreleaseInfo) {
    $latestReleaseTag = $wingetreleaseInfo.tag_name
    $assetUrl = ($wingetreleaseInfo.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url
    if ($assetUrl) {
        $wingetoutputFile = Join-Path -Path $savePath -ChildPath "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe-$latestReleaseTag.msixbundle"
        if (-not (Test-Path -Path $wingetoutputFile)) {
            Invoke-WebRequest -Uri $assetUrl -OutFile $wingetoutputFile
            Write-Host "Downloaded $repo release $latestReleaseTag"
        }
    }
    else {
        Write-Host "No .msixbundle asset found in the latest release of $repo"
    }
}
else {
    Write-Host "Failed to retrieve the latest release of $repo"
}

if (!(Test-Path ".\Microsoft.VCLibs.x64.14.00.Desktop.appx")) {
    Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile ".\Microsoft.VCLibs.x64.14.00.Desktop.appx"
}

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Add-AppxPackage -Path ".\Microsoft.VCLibs.x64.14.00.Desktop.appx"

Add-AppxPackage -Path $wingetoutputFile

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco feature enable -n allowGlobalConfirmation

if (Test-Path .\pwshModules.txt) {
    foreach ($line in Get-Content ".\pwshModules.txt") {
        Install-Module $line -Force
        Write-Host("Installed $line")
    }
}
if (Test-Path .\chocoPackages.txt) {
    foreach ($line in Get-Content ".\chocoPackages.txt") {
        choco install $line
    }
}
if (Test-Path .\wingetPackages.txt) {
    foreach ($line in Get-Content ".\wingetPackages.txt") {
        winget install $line --accept-package-agreements --accept-source-agreements
    }
}