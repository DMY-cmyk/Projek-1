param(
    [string]$OutputsDir = "outputs",
    [string]$OutPath = "outputs/manifest.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Path $OutputsDir -Recurse -File
$manifest = @()

foreach ($f in $files) {
    $hash = Get-FileHash -Path $f.FullName -Algorithm SHA256
    $manifest += [pscustomobject]@{
        path = $f.FullName.Replace((Resolve-Path $OutputsDir).Path + [IO.Path]::DirectorySeparatorChar, "outputs" + [IO.Path]::DirectorySeparatorChar)
        size_bytes = $f.Length
        sha256 = $hash.Hash
        modified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutPath -Encoding utf8
Write-Host "Done. Wrote outputs manifest to $OutPath."
