<#
.SYNOPSIS
    NetPulse Observer Engine v2.0 - Med Incident Alerting.
#>

$ConfigPath = "$PSScriptRoot\..\config\Targets.json"
$LogDir = "$PSScriptRoot\..\logs"
$CsvPath = "$LogDir\PulseData.csv"

if (!(Test-Path $ConfigPath)) { Throw "Konfigurasjon mangler!" }
$Config = Get-Content $ConfigPath | ConvertFrom-Json
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force }

function Send-PulseAlert {
    param($Result)
    $Subject = "[NetPulse ALERT] $($Result.Status): $($Result.Name)"
    $Body = "Kritisk nettverkshendelse detektert!`n`nNavn: $($Result.Name)`nAdresse: $($Result.Address)`nStatus: $($Result.Status)`nLatens: $($Result.Latency)ms`nTap: $($Result.Loss)`nTid: $($Result.Timestamp)"
    
    # Simulering av e-post (Viktig for porteføljen å vise logikken)
    Write-Host "--- VARSEL SENDT TIL $($Config.Settings.AlertEmail) ---" -ForegroundColor Yellow
    Write-Host "Emne: $Subject" -ForegroundColor Yellow
}

function Get-PulseScan {
    param($Endpoint)
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Latencies = @()
    $LostPackets = 0
    
    for ($i = 0; $i -lt $Config.Settings.PingCount; $i++) {
        try {
            $Reply = $Ping.Send($Endpoint.Address, 1000)
            if ($Reply.Status -eq "Success") { $Latencies += $Reply.RoundtripTime }
            else { $LostPackets++ }
        } catch { $LostPackets++ }
    }

    $Avg = if ($Latencies.Count -gt 0) { ($Latencies | Measure-Object -Average).Average } else { 0 }
    $Jitter = if ($Latencies.Count -gt 1) { 
        $Diffs = for ($i = 1; $i -lt $Latencies.Count; $i++) { [Math]::Abs($Latencies[$i] - $Latencies[$i-1]) }
        ($Diffs | Measure-Object -Average).Average 
    } else { 0 }

    $PortStatus = "N/A"
    if ($Endpoint.Port) {
        $Tcp = New-Object System.Net.Sockets.TcpClient
        $Wait = $Tcp.BeginConnect($Endpoint.Address, $Endpoint.Port, $null, $null).AsyncWaitHandle.WaitOne(500, $false)
        $PortStatus = if ($Wait -and $Tcp.Connected) { "Open" } else { "Closed" }
        $Tcp.Close()
    }

    $Status = if ($LostPackets -eq $Config.Settings.PingCount) { "Offline" } elseif ($Avg -gt $Config.Settings.CriticalThresholdMS) { "Critical" } else { "Healthy" }

    $Result = [PSCustomObject]@{
        Timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Name       = $Endpoint.Name
        Address    = $Endpoint.Address
        Latency    = [Math]::Round($Avg, 2)
        Jitter     = [Math]::Round($Jitter, 2)
        Loss       = "$(([Math]::Round(($LostPackets / $Config.Settings.PingCount) * 100, 0)))%"
        Port       = $PortStatus
        Status     = $Status
    }

    # Trigger varsling hvis noe er galt
    if ($Status -ne "Healthy") { Send-PulseAlert -Result $Result }

    return $Result
}

$Results = foreach ($Target in $Config.MonitoredEndpoints) { Get-PulseScan -Endpoint $Target }
$Results | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding utf8

# Logg-rotasjon
$LimitDate = (Get-Date).AddDays(-$Config.Settings.LogRetentionDays)
if (Test-Path $CsvPath) {
    $CleanData = Import-Csv $CsvPath | Where-Object { [datetime]$_.Timestamp -gt $LimitDate }
    $CleanData | Export-Csv -Path $CsvPath -Force -NoTypeInformation -Encoding utf8
}

Write-Host "NetPulse-syklus fullfort." -ForegroundColor Green