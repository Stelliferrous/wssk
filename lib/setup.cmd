set "modeArgument=%~1"

if not "%modeArgument%"=="" (
    set "argumentList=C:\\Users\\WDAGUtilityAccount\\Documents\\wssk\\lib\\setup.ps1, -mode, %modeArgument%"
) else (
    set "argumentList='C:\\Users\\WDAGUtilityAccount\\Documents\\wssk\\lib\\setup.ps1'"
)

"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command Start-Process -wait powershell -ArgumentList %argumentList%
