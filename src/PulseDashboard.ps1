$CsvPath = "$PSScriptRoot\..\logs\PulseData.csv"
$HtmlPath = "$PSScriptRoot\..\logs\PulseDashboard.html"

if (!(Test-Path $CsvPath)) { Write-Error "Ingen data funnet."; exit }

$FullData = Import-Csv $CsvPath
$UniqueNames = $FullData.Name | Select-Object -Unique

$HtmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: #1e293b; padding: 25px; border-radius: 15px; border-top: 4px solid #38bdf8; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.5); }
        .Critical { border-top-color: #ef4444; }
        .Offline { border-top-color: #64748b; }
        h1 { font-size: 2em; margin-bottom: 30px; color: #38bdf8; }
        .stat-value { font-size: 2.2em; font-weight: 800; margin: 10px 0; }
        .label { color: #94a3b8; font-size: 0.85em; text-transform: uppercase; letter-spacing: 1px; }
        .flex { display: flex; justify-content: space-between; margin-top: 15px; padding-top: 15px; border-top: 1px solid #334155; }
    </style>
</head>
<body>
    <h1>NetPulse Observer - Live Status</h1>
    <div class="grid">
"@

$HtmlBody = ""
foreach ($Name in $UniqueNames) {
    $Latest = $FullData | Where-Object { $_.Name -eq $Name } | Select-Object -Last 1
    
    $HtmlBody += @"
    <div class="card $($Latest.Status)">
        <div class="label">$($Latest.Name)</div>
        <div class="stat-value">$($Latest.Latency) ms</div>
        <div class="flex">
            <div><span class="label">Jitter:</span> $($Latest.Jitter)ms</div>
            <div><span class="label">Tap:</span> $($Latest.Loss)</div>
        </div>
        <div class="flex">
            <div><span class="label">Port:</span> $($Latest.Port)</div>
            <div style="font-size: 0.7em; color: #64748b;">$($Latest.Timestamp)</div>
        </div>
    </div>
"@
}

$HtmlFooter = "</div></body></html>"
$HtmlHeader + $HtmlBody + $HtmlFooter | Out-File $HtmlPath -Encoding utf8