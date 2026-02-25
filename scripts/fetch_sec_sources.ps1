param(
    [string]$Cik = "0000320193",
    [string]$UserAgent = "Your Name your.email@example.com",
    [string]$OutDir = "research/sec",
    [switch]$ForceFresh
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
$statusLogPath = Join-Path $OutDir "request_status.csv"
$fetchStatusPath = "outputs/fetch_status.md"

function Log-Request([string]$url, [string]$path) {
    $line = "{0},{1},{2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $url, $path
    if (-not (Test-Path $logPath)) {
        "timestamp,url,path" | Out-File -FilePath $logPath -Encoding utf8
    }
    $line | Out-File -FilePath $logPath -Append -Encoding utf8
}

function Log-RequestStatus([string]$url, [string]$path, [string]$statusCode, [bool]$ok, [string]$message) {
    $line = "{0},{1},{2},{3},{4},{5}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $url, $path, $statusCode, $ok, $message
    if (-not (Test-Path $statusLogPath)) {
        "timestamp,url,path,status_code,ok,message" | Out-File -FilePath $statusLogPath -Encoding utf8
    }
    $line | Out-File -FilePath $statusLogPath -Append -Encoding utf8
}

function Invoke-SecGet([string]$url, [string]$outFile, [int]$MaxAttempts = 3, [int]$BaseDelaySeconds = 2) {
    $attempt = 0
    while ($attempt -lt $MaxAttempts) {
        $attempt++
        try {
            $resp = Invoke-WebRequest -Uri $url -Headers $headers -OutFile $outFile -PassThru
            $statusCode = $resp.StatusCode
            Log-Request $url $outFile
            Log-RequestStatus $url $outFile $statusCode $true ""
            Start-Sleep -Milliseconds 200
            return @{ Success = $true; StatusCode = $statusCode; UsedCache = $false }
        } catch {
            $msg = $_.Exception.Message
            Log-RequestStatus $url $outFile "" $false $msg
            if ($attempt -lt $MaxAttempts) {
                $delay = [math]::Pow(2, $attempt - 1) * $BaseDelaySeconds
                Start-Sleep -Seconds $delay
            }
        }
    }
    return @{ Success = $false; StatusCode = $null; UsedCache = $false }
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
}
if (-not (Test-Path (Join-Path $OutDir "filings"))) {
    New-Item -ItemType Directory -Force (Join-Path $OutDir "filings") | Out-Null
}
if (-not (Test-Path "outputs")) {
    New-Item -ItemType Directory -Force "outputs" | Out-Null
}

$submissionsUrl = "https://data.sec.gov/submissions/CIK$Cik.json"
$submissionsPath = Join-Path $OutDir ("submissions_{0}.json" -f $today)
$submissionsResult = Invoke-SecGet $submissionsUrl $submissionsPath
$submissions = $null
$submissionsUsedCache = $false
if ($submissionsResult.Success -and (Test-Path $submissionsPath)) {
    $submissions = Get-Content $submissionsPath -Raw | ConvertFrom-Json
} elseif (-not $ForceFresh) {
    $fallbackSub = Get-ChildItem -Path $OutDir -Filter "submissions_*.json" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    if ($fallbackSub) {
        Write-Warning ("Using cached submissions: {0}" -f $fallbackSub.Name)
        $submissions = Get-Content $fallbackSub.FullName -Raw | ConvertFrom-Json
        $submissionsUsedCache = $true
    } else {
        Write-Warning "No submissions file available; skipping filings download."
    }
} else {
    Write-Warning "ForceFresh enabled and submissions download failed; skipping filings download."
}

$companyfactsUrl = "https://data.sec.gov/api/xbrl/companyfacts/CIK$Cik.json"
$companyfactsPath = Join-Path $OutDir ("companyfacts_{0}.json" -f $today)
$companyfactsResult = Invoke-SecGet $companyfactsUrl $companyfactsPath
$companyfactsUsedCache = $false
if ((-not $companyfactsResult.Success -or -not (Test-Path $companyfactsPath)) -and -not $ForceFresh) {
    $fallbackFacts = Get-ChildItem -Path $OutDir -Filter "companyfacts_*.json" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    if ($fallbackFacts) {
        Write-Warning ("Using cached companyfacts: {0}" -f $fallbackFacts.Name)
        $companyfactsUsedCache = $true
    } else {
        Write-Warning "No companyfacts file available."
    }
} elseif ((-not $companyfactsResult.Success -or -not (Test-Path $companyfactsPath)) -and $ForceFresh) {
    Write-Warning "ForceFresh enabled and companyfacts download failed."
}

$companyfactsAvailable = (($companyfactsResult.Success -and (Test-Path $companyfactsPath)) -or $companyfactsUsedCache)
if (-not $companyfactsAvailable) {
    Write-Error "No companyfacts file available; cannot proceed."
    exit 1
}

$filingsDownloaded = 0
$filingsFailed = 0
$filingsAttempted = 0
if ($null -ne $submissions) {
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
        $filingsAttempted++
        $result = Invoke-SecGet $docUrl $outFile
        if ($result.Success) {
            $filingsDownloaded++
        } else {
            $filingsFailed++
        }
    }
}

$freshUsed = ($submissionsResult.Success -or $companyfactsResult.Success -or $filingsDownloaded -gt 0)
$submissionsStatus = if ($submissionsResult.Success) { "downloaded" } elseif ($submissionsUsedCache) { "cached" } else { "failed" }
$factsStatus = if ($companyfactsResult.Success) { "downloaded" } elseif ($companyfactsUsedCache) { "cached" } else { "failed" }
$filingsStatus = if ($null -eq $submissions) { "skipped" } elseif ($filingsFailed -gt 0 -and $filingsDownloaded -eq 0) { "failed" } else { "partial_or_ok" }

$statusLines = @(
    "# SEC fetch status",
    "",
    ("* Timestamp: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")),
    ("* CIK: {0}" -f $Cik),
    ("* Submissions: {0}" -f $submissionsStatus),
    ("* Company facts: {0}" -f $factsStatus),
    ("* Filings: {0} (attempted: {1}, downloaded: {2}, failed: {3})" -f $filingsStatus, $filingsAttempted, $filingsDownloaded, $filingsFailed),
    ("* Fresh data used: {0}" -f ($freshUsed.ToString().ToLower())),
    ("* ForceFresh: {0}" -f ($ForceFresh.ToString().ToLower()))
)
$statusLines = $statusLines | ForEach-Object { $_.TrimEnd() }
if (Test-Path $fetchStatusPath) {
    "" | Out-File -FilePath $fetchStatusPath -Append -Encoding utf8
    $statusLines | Out-File -FilePath $fetchStatusPath -Append -Encoding utf8
} else {
    $statusLines | Out-File -FilePath $fetchStatusPath -Encoding utf8
}

Write-Host "Done. Files saved under $OutDir."
