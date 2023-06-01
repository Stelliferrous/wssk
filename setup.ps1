Set-ExecutionPolicy Bypass
$savePath = "C:\Users\WDAGUtilityAccount\Documents\wssk\"
Set-Location $savePath
Import-Module .\lib\functions.ps1

if (Test-Path .\pwshModules.txt) {
    foreach ($line in Get-Content ".\pwshModules.txt") {
        Install-Module $line -Force
        Write-Host("Installed $line")
    }
}
if (Test-Path .\wingetPackages.txt) {
    $wingetInstallResults = wingetInstall
    if ($wingetInstallResults.Success) {
        foreach ($line in Get-Content ".\wingetPackages.txt") {
            winget install $line --accept-package-agreements --accept-source-agreements
        }
    } else {
        Write-Host($wingetInstallResults.Message)    
    }
}
if (Test-Path .\chocoPackages.txt) {
    $chocolateyInstallResults = chocolateyInstall
    if ($chocolateyInstallResults.Success) {
        foreach ($line in Get-Content ".\chocoPackages.txt") {
            choco install $line -y
        }
    } else {
        Write-Host($chocolateyInstallResults.Message)
    }
}