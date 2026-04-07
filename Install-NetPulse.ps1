# Oppretter en planlagt oppgave som kjører NetPulse hvert 5. minutt
$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -File `"$PSScriptRoot\src\NetPulse.ps1`""
$Trigger = New-ScheduledTaskTrigger -At (Get-Date) -Once -RepetitionInterval (New-TimeSpan -Minutes 5)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "NetPulse_Observer" -Action $Action -Trigger $Trigger -Settings $Settings -Force

Write-Host "NetPulse Observer er na installert og kjører hvert 5. minutt!" -ForegroundColor Cyan