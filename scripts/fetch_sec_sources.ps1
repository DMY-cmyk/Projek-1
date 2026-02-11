param(
    [string]$Cik = "0000320193",
    [string]$UserAgent = "Your Name your.email@example.com",
    [string]$OutDir = "research/sec"
)

if ($UserAgent -match "Your Name") {
    Write-Error "Set -UserAgent to a real name and email per SEC guidance."
    exit 1
}

$headers = @{
    "User-Agent"      = $UserAgent
    "Accept"          = "application/json"
    "Accept-Encoding" = "gzip, deflate"
}

$today = Get-Date -Format "yyyy-MM-dd"
$logPath = Join-Path $OutDir "request_log.csv"

function Log-Request([string]$url, [string]$path) {
    $line = "{0},{1},{2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $url, $path
    if (-not (Test-Path $logPath)) {
        "timestamp,url,path" | Out-File -FilePath $logPath -Encoding utf8
    }
    $line | Out-File -FilePath $logPath -Append -Encoding utf8
}

function Invoke-SecGet([string]$url, [string]$outFile) {
    Invoke-WebRequest -Uri $url -Headers $headers -OutFile $outFile
    Log-Request $url $outFile
    Start-Sleep -Milliseconds 200
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
}
if (-not (Test-Path (Join-Path $OutDir "filings"))) {
    New-Item -ItemType Directory -Force (Join-Path $OutDir "filings") | Out-Null
}

$submissionsUrl = "https://data.sec.gov/submissions/CIK$Cik.json"
$submissionsPath = Join-Path $OutDir ("submissions_{0}.json" -f $today)
Invoke-SecGet $submissionsUrl $submissionsPath
$submissions = Get-Content $submissionsPath -Raw | ConvertFrom-Json

$companyfactsUrl = "https://data.sec.gov/api/xbrl/companyfacts/CIK$Cik.json"
$companyfactsPath = Join-Path $OutDir ("companyfacts_{0}.json" -f $today)
Invoke-SecGet $companyfactsUrl $companyfactsPath

$recent = $submissions.filings.recent
$forms = $recent.form
$accessions = $recent.accessionNumber
$primaryDocs = $recent.primaryDocument
$filingDates = $recent.filingDate

function Get-LatestIndex([string]$formType) {
    for ($i = 0; $i -lt $forms.Count; $i++) {
        if ($forms[$i] -eq $formType) {
            return $i
        }
    }
    return -1
}

$cikNoZeros = ($Cik -replace "^0+", "")
$targets = @("10-K", "10-Q", "8-K")
foreach ($formType in $targets) {
    $idx = Get-LatestIndex $formType
    if ($idx -lt 0) {
        Write-Warning "No recent $formType found in submissions."
        continue
    }
    $accNo = $accessions[$idx] -replace "-", ""
    $primaryDoc = $primaryDocs[$idx]
    $filingDate = $filingDates[$idx]
    $docUrl = "https://www.sec.gov/Archives/edgar/data/$cikNoZeros/$accNo/$primaryDoc"
    $safeDoc = $primaryDoc -replace "[\\\\/:*?\""<>\|]", "_"
    $outFile = Join-Path $OutDir ("filings/{0}_{1}_{2}" -f $formType, $filingDate, $safeDoc)
    Invoke-SecGet $docUrl $outFile
}

Write-Host "Done. Files saved under $OutDir."
