param(
    [string]$OutDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$statusPath = Join-Path $OutDir "fetch_status.md"
$errorsPath = Join-Path $OutDir "fetch_errors.md"

if (-not (Test-Path $statusPath)) {
    Write-Host "No fetch_status.md found."
    exit 0
}

$status = Get-Content -Path $statusPath
$timestamp = ($status | Select-String -Pattern "^\* Timestamp:").Line
$fresh = ($status | Select-String -Pattern "^\* Fresh data used:").Line
$preflight = $status | Select-String -Pattern "^# SEC connectivity preflight" -AllMatches
$lastPreflightIdx = if ($preflight.Matches.Count -gt 0) { $preflight.Matches[-1].Index } else { -1 }

Write-Host "SEC Fetch Summary"
Write-Host "-----------------"
if ($timestamp) { Write-Host $timestamp.Trim() }
if ($fresh) { Write-Host $fresh.Trim() }

if ($lastPreflightIdx -ge 0) {
    $tail = $status[$lastPreflightIdx..($status.Count - 1)]
    $urls = @()
    for ($i = 0; $i -lt $tail.Count; $i++) {
        if ($tail[$i] -like "* URL:*") {
            $url = $tail[$i].Replace("* URL:","").Trim()
            $statusLine = ""
            $codeLine = ""
            $latLine = ""
            if ($i + 1 -lt $tail.Count) { $statusLine = $tail[$i+1].Trim() }
            if ($i + 2 -lt $tail.Count) { $codeLine = $tail[$i+2].Trim() }
            if ($i + 3 -lt $tail.Count) { $latLine = $tail[$i+3].Trim() }
            $urls += ("{0} | {1} | {2} | {3}" -f $url, $statusLine, $codeLine, $latLine)
        }
    }
    if ($urls.Count -gt 0) {
        Write-Host ""
        Write-Host "Preflight (latest)"
        Write-Host "------------------"
        $urls | ForEach-Object { Write-Host $_ }
    }
}

if (Test-Path $errorsPath) {
    $errors = Get-Content -Path $errorsPath
    $lastError = ($errors | Select-String -Pattern "^- " | Select-Object -Last 1).Line
    if ($lastError) {
        Write-Host ""
        Write-Host "Last Error"
        Write-Host "----------"
        Write-Host $lastError.Trim()
    }
}
