$json = Get-Content 'research/sec/companyfacts_2026-02-11.json' -Raw | ConvertFrom-Json
$facts = $json.facts.'us-gaap'

$tags = @("LongTermDebt", "CommercialPaper", "LongTermDebtNoncurrent", "LongTermDebtCurrent", "ShortTermBorrowings")
foreach ($tag in $tags) {
    Write-Host "=== $tag ==="
    if (-not $facts.PSObject.Properties.Name.Contains($tag)) {
        Write-Host "  (tag not found)"
        continue
    }
    $units = $facts.$tag.units
    foreach ($unitName in $units.PSObject.Properties.Name) {
        Write-Host "  Unit: $unitName"
        $entries = $units.$unitName | Where-Object { $_.form -eq '10-K' -and $_.fp -eq 'FY' }
        foreach ($e in $entries) {
            $valB = [math]::Round($e.val / 1000000000, 3)
            Write-Host ("  FY{0}: {1}B" -f $e.fy, $valB)
        }
    }
}
