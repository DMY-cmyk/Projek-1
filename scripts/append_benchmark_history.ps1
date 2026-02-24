param(
    [string]$OutPath = "outputs/benchmark_history.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Load-Csv([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    return Import-Csv $path
}

$multiples = Load-Csv "data/peer_multiples.csv"
if (-not $multiples) {
    Write-Error "Missing data/peer_multiples.csv"
    exit 1
}

$now = Get-Date
$rows = @()
foreach ($m in $multiples) {
    $rows += [pscustomobject]@{
        captured_at = $now.ToString("yyyy-MM-dd HH:mm:ss")
        company = $m.Company
        ticker = $m.Ticker
        as_of_date = $m.AsOfDate
        pe = $m.PE
        ev_ebitda = $m.EV_EBITDA
        p_fcf = $m.P_FCF
    }
}

if (Test-Path $OutPath) {
    $existing = Import-Csv $OutPath
    if ($existing) {
        $lastCaptured = ($existing | Sort-Object -Property captured_at | Select-Object -Last 1).captured_at
        $lastSnapshot = $existing | Where-Object { $_.captured_at -eq $lastCaptured }
        if ($lastSnapshot) {
            $same = $true
            if ($lastSnapshot.Count -ne $rows.Count) {
                $same = $false
            } else {
                foreach ($r in $rows) {
                    $match = $lastSnapshot | Where-Object {
                        $_.company -eq $r.company -and
                        $_.ticker -eq $r.ticker -and
                        $_.as_of_date -eq $r.as_of_date -and
                        $_.pe -eq $r.pe -and
                        $_.ev_ebitda -eq $r.ev_ebitda -and
                        $_.p_fcf -eq $r.p_fcf
                    } | Select-Object -First 1
                    if (-not $match) {
                        $same = $false
                        break
                    }
                }
            }
            if ($same) {
                Write-Host "No changes vs last snapshot. Skipping append."
                exit 0
            }
        }
    }
}

if (-not (Test-Path $OutPath)) {
    $rows | Export-Csv -Path $OutPath -NoTypeInformation
} else {
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Append
}

Write-Host "Done. Appended benchmark history to $OutPath."
