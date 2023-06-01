
param (
    [Parameter(Mandatory = $false)]
    [String]$mode = "personal"
)

Set-ExecutionPolicy Bypass
$savePath = "C:\Users\WDAGUtilityAccount\Documents\wssk\"
Set-Location $savePath
Import-Module .\lib\functions.ps1

$pwshModules = (Join-Path $mode "\pwshModules.txt")
if (Test-Path $pwshModules) {
    foreach ($line in Get-Content $pwshModules) {
        Install-Module $line -Force
        Write-Host("Installed $line")
    }
}
$wingetPackages = (Join-Path $mode "\wingetPackages.txt")
if (Test-Path $wingetPackages) {
    $wingetInstallResults = wingetInstall
    if ($wingetInstallResults.Success) {
        foreach ($line in Get-Content $wingetPackages) {
            winget install $line --accept-package-agreements --accept-source-agreements
        }
    } else {
        Write-Host($wingetInstallResults.Message)    
    }
}
$chocoPackages = Join-Path $mode "\chocoPackages.txt"
if (Test-Path $chocoPackages) {
    $chocolateyInstallResults = chocolateyInstall
    if ($chocolateyInstallResults.Success) {
        foreach ($line in Get-Content $chocoPackages) {
            choco install $line -y
        }
    } else {
        Write-Host($chocolateyInstallResults.Message)
    }
}