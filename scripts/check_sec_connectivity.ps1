param(
    [string]$UserAgent,
    [string]$Url = "https://data.sec.gov/api/xbrl/companyfacts/CIK0000320193.json",
    [int]$TimeoutSeconds = 15,
    [string]$OutPath = "outputs/fetch_status.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

if (-not (Test-Path "outputs")) {
    New-Item -ItemType Directory -Force "outputs" | Out-Null
}

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$status = "unknown"
$statusCode = ""
$latencyMs = ""
$message = ""

try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-WebRequest -Uri $Url -Headers @{ "User-Agent" = $UserAgent; "Accept" = "application/json" } -Method Head -TimeoutSec $TimeoutSeconds -PassThru
    $sw.Stop()
    $status = "ok"
    $statusCode = $resp.StatusCode
    $latencyMs = $sw.ElapsedMilliseconds
} catch {
    $status = "failed"
    $message = $_.Exception.Message
}

$lines = @(
    "# SEC connectivity preflight",
    "",
    ("* Timestamp: {0}" -f $ts),
    ("* URL: {0}" -f $Url),
    ("* Status: {0}" -f $status),
    ("* Status code: {0}" -f $statusCode),
    ("* Latency ms: {0}" -f $latencyMs),
    ("* Message: {0}" -f $message)
)

if (Test-Path $OutPath) {
    "" | Out-File -FilePath $OutPath -Append -Encoding utf8
    $lines | Out-File -FilePath $OutPath -Append -Encoding utf8
} else {
    $lines | Out-File -FilePath $OutPath -Encoding utf8
}

Write-Host "Preflight written to $OutPath."
