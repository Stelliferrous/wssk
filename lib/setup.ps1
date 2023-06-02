
param (
    [Parameter(Mandatory = $false)]
    [String]$mode = "personal"
)

Set-ExecutionPolicy Bypass
$savePath = "C:\Users\WDAGUtilityAccount\Documents\wssk\"
$modePath = Join-Path ".\modes\" $mode
Set-Location $savePath
Import-Module -Name .\lib\functions
Import-Module -Name $modePath\settings

$settings = loadSettingsVars

if ($settings.regHacks) {
    $explorerRestart = $false
    foreach ($hack in $settings.regHacks) {
        registryEditor -regPath $hack.path -regName $hack.name -regValue $hack.value
        if ($hack.restart) {
            $explorerRestart = $true
        }
    }
    if ($explorerRestart) {
        explorerRestart
    }
}

if ($settings.pwshModules) {
    $nugetInstallResults = nugetInstall
    if ($nugetInstallResults.Success) {
        foreach ($line in $settings.pwshModules) {
            Install-Module $line -Force
            Write-Host("Installed $line")
        }
    }
}

if ($settings.wingetPackages) {
    $wingetInstallResults = wingetInstall
    if ($wingetInstallResults.Success) {
        foreach ($line in $settings.wingetPackages) {
            winget install $line --accept-package-agreements --accept-source-agreements
        }
    } else {
        Write-Host($wingetInstallResults.Message)    
    }
}

if ($settings.chocoPackages) {
    $chocolateyInstallResults = chocolateyInstall
    if ($chocolateyInstallResults.Success) {
        foreach ($line in $settings.chocoPackages) {
            choco install $line -y
        }
    } else {
        Write-Host($chocolateyInstallResults.Message)
    }
}
