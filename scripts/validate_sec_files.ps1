param(
    [string]$OutDir = "research/sec"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutDir)) {
    Write-Host "No SEC cache directory found: $OutDir"
    exit 0
}

function Get-Latest([string]$pattern) {
    return Get-ChildItem -Path $OutDir -Filter $pattern | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
}

$files = @(
    @{ Label = "Submissions"; Pattern = "submissions_*.json" },
    @{ Label = "Companyfacts"; Pattern = "companyfacts_*.json" }
)

Write-Host "SEC Cache Validation"
Write-Host "-------------------"

foreach ($f in $files) {
    $file = Get-Latest $f.Pattern
    if (-not $file) {
        Write-Host ("{0}: MISSING" -f $f.Label)
        continue
    }
    if ($file.Length -le 2) {
        Write-Host ("{0}: EMPTY ({1})" -f $f.Label, $file.Name)
        continue
    }
    try {
        $null = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json
        Write-Host ("{0}: OK ({1})" -f $f.Label, $file.Name)
    } catch {
        Write-Host ("{0}: INVALID JSON ({1})" -f $f.Label, $file.Name)
    }
}
