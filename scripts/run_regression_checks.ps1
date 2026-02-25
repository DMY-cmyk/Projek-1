Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Error $message
        exit 1
    }
}

$root = Get-Location
$tmp = Join-Path $env:TEMP ("projek1-regression-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $tmp | Out-Null

try {
    $outDir = Join-Path $tmp "outputs"
    New-Item -ItemType Directory -Force $outDir | Out-Null

    # verify_outputs should fail when a required file is missing
    "x" | Out-File -FilePath (Join-Path $outDir "report.md") -Encoding utf8
    "x" | Out-File -FilePath (Join-Path $outDir "run_log.md") -Encoding utf8
    "x" | Out-File -FilePath (Join-Path $outDir "summary.json") -Encoding utf8
    "x" | Out-File -FilePath (Join-Path $outDir "manifest.json") -Encoding utf8
    "x" | Out-File -FilePath (Join-Path $outDir "freshness_report.md") -Encoding utf8
    $verifyCmd = "powershell -ExecutionPolicy Bypass -File scripts/verify_outputs.ps1 -OutDir `"$outDir`" >nul 2>nul"
    cmd.exe /c $verifyCmd | Out-Null
    $failed = ($LASTEXITCODE -ne 0)
    Assert-True $failed "verify_outputs.ps1 should fail when versions.md is missing."

    # verify_outputs should pass when all required files exist
    "x" | Out-File -FilePath (Join-Path $outDir "versions.md") -Encoding utf8
    cmd.exe /c $verifyCmd | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) "verify_outputs.ps1 should pass with all required files."

    # print_versions should generate a markdown file
    $versionsOut = Join-Path $tmp "versions.md"
    & powershell.exe -ExecutionPolicy Bypass -File scripts/print_versions.ps1 -OutPath $versionsOut | Out-Null
    Assert-True (Test-Path $versionsOut) "print_versions.ps1 did not create output file."
    $txt = Get-Content -Raw $versionsOut
    Assert-True ($txt -match "# Tool Versions") "print_versions.ps1 output content is invalid."

    # fetch_sec_retry still exposes expected hardening flags
    $fetchScript = Get-Content -Raw scripts/fetch_sec_retry.ps1
    Assert-True ($fetchScript -match '\[switch\]\$ForceFresh') "fetch_sec_retry.ps1 missing -ForceFresh switch."
    Assert-True ($fetchScript -match '\[switch\]\$FailFast') "fetch_sec_retry.ps1 missing -FailFast switch."

    Write-Host "Regression checks OK."
} finally {
    if (Test-Path $tmp) {
        Remove-Item -Recurse -Force $tmp
    }
    Set-Location $root
}
