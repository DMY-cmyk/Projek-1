param(
    [string]$OutDir = "outputs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $OutDir)) {
    Write-Host "No outputs directory found."
    exit 0
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$targets = @("fetch_status.md", "fetch_errors.md")

foreach ($name in $targets) {
    $path = Join-Path $OutDir $name
    if (Test-Path $path) {
        $archived = Join-Path $OutDir ("{0}.{1}" -f $name, $ts)
        Move-Item -Path $path -Destination $archived
        Write-Host ("Archived {0} -> {1}" -f $name, (Split-Path $archived -Leaf))
    }
}
