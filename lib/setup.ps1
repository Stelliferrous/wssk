
param (
    [Parameter(Mandatory = $false)]
    [String]$mode = "personal"
)


Set-ExecutionPolicy Bypass
$savePath = "C:\Users\WDAGUtilityAccount\Documents\wssk\"
$modePath = Join-Path ".\modes\" $mode
Set-Location $savePath
Import-Module .\lib\functions.ps1
Import-Module $modePath\settings.ps1

if ($pwshModules) {
    foreach ($line in $pwshModules) {
        Install-Module $line -Force
        Write-Host("Installed $line")
    }
}

if ($wingetPackages) {
    $wingetInstallResults = wingetInstall
    if ($wingetInstallResults.Success) {
        foreach ($line in $wingetPackages) {
            winget install $line --accept-package-agreements --accept-source-agreements
        }
    } else {
        Write-Host($wingetInstallResults.Message)    
    }
}

if ($chocoPackages) {
    $chocolateyInstallResults = chocolateyInstall
    if ($chocolateyInstallResults.Success) {
        foreach ($line in $chocoPackages) {
            choco install $line -y
        }
    } else {
        Write-Host($chocolateyInstallResults.Message)
    }
}