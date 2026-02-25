param(
    [string]$OutPath = "outputs/versions.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CommandOutput([scriptblock]$Command) {
    try {
        $output = & $Command 2>$null
        if ($null -eq $output) {
            return "Not available"
        }
        $text = ($output | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            return "Not available"
        }
        return $text
    } catch {
        return "Not available"
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$psVersion = $PSVersionTable.PSVersion.ToString()
$psEdition = $PSVersionTable.PSEdition
$psText = "$psVersion ($psEdition)"

$gitText = Get-CommandOutput { & git --version }
$rustcText = Get-CommandOutput { & rustc --version }
$cargoText = Get-CommandOutput { & cargo --version }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Tool Versions")
$lines.Add("")
$lines.Add("Generated: $timestamp")
$lines.Add("")
$lines.Add("| Tool | Version |")
$lines.Add("| --- | --- |")
$lines.Add("| PowerShell | $psText |")
$lines.Add("| Git | $gitText |")
$lines.Add("| Rust (rustc) | $rustcText |")
$lines.Add("| Rust (cargo) | $cargoText |")

$outDir = Split-Path $OutPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force $outDir | Out-Null
}
$lines | Out-File -FilePath $OutPath -Encoding utf8

Write-Host "Done. Wrote tool versions to $OutPath."
Write-Host ""
$lines | ForEach-Object { Write-Host $_ }
