param(
    [string]$UserAgent,
    [int]$MaxAttempts = 3,
    [int]$BaseDelaySeconds = 5,
    [string]$ErrorLog = "outputs/fetch_errors.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Write-Error "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
    exit 1
}

function Write-ErrorLog([string]$message) {
    $outDir = Split-Path $ErrorLog -Parent
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Force $outDir | Out-Null
    }
    $line = ("- {0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $message)
    if (-not (Test-Path $ErrorLog)) {
        "# SEC Fetch Errors`n" | Out-File -FilePath $ErrorLog -Encoding utf8
    }
    $line | Out-File -FilePath $ErrorLog -Encoding utf8 -Append
}

$attempt = 0
$success = $false
while ($attempt -lt $MaxAttempts -and -not $success) {
    $attempt++
    Write-Host ("Attempt {0}/{1}..." -f $attempt, $MaxAttempts)
    try {
        & powershell.exe -ExecutionPolicy Bypass -File scripts/fetch_sec_sources.ps1 -UserAgent $UserAgent
        if ($LASTEXITCODE -eq 0) {
            $success = $true
        } else {
            Write-ErrorLog ("Attempt {0} failed with exit code {1}" -f $attempt, $LASTEXITCODE)
        }
    } catch {
        Write-ErrorLog ("Attempt {0} error: {1}" -f $attempt, $_.Exception.Message)
    }
    if (-not $success -and $attempt -lt $MaxAttempts) {
        $delay = [math]::Pow(2, $attempt - 1) * $BaseDelaySeconds
        Write-Host ("Retrying in {0} seconds..." -f $delay)
        Start-Sleep -Seconds $delay
    }
}

if (-not $success) {
    Write-Error "SEC fetch failed after $MaxAttempts attempts. See $ErrorLog"
    exit 1
}

Write-Host "SEC fetch completed."
