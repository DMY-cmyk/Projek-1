param(
    [int]$MaxAgeDays = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Refreshing peer fundamentals..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/update_peer_fundamentals.ps1
$fundExit = $LASTEXITCODE
if ($fundExit -ne 0) {
    Write-Error "update_peer_fundamentals.ps1 failed with exit code $fundExit"
    exit 1
}

Write-Host "Refreshing peer multiples..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/update_peer_multiples.ps1
$updateExit = $LASTEXITCODE

Write-Host "Validating peer datasets..."
& powershell.exe -ExecutionPolicy Bypass -File scripts/verify_peer_data.ps1 -MaxAgeDays $MaxAgeDays
$verifyExit = $LASTEXITCODE

if ($updateExit -ne 0) {
    Write-Error "update_peer_multiples.ps1 failed with exit code $updateExit"
    exit 1
}
if ($verifyExit -ne 0) {
    Write-Error "verify_peer_data.ps1 failed with exit code $verifyExit"
    exit 1
}
