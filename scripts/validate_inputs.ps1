param(
    [string]$AsOfDate,
    [double]$Price,
    [string]$UserAgent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$msg) {
    Write-Error $msg
    exit 1
}

if (-not $UserAgent -or $UserAgent.Trim().Length -lt 6) {
    Fail "UserAgent is required. Example: -UserAgent \"Name email@domain.com\""
}

if (-not $AsOfDate -or $AsOfDate -notmatch '^\d{4}-\d{2}-\d{2}$') {
    Fail "AsOfDate must be in YYYY-MM-DD format."
}

try {
    [void][datetime]::ParseExact($AsOfDate, "yyyy-MM-dd", $null)
} catch {
    Fail "AsOfDate is not a valid date."
}

if ($Price -le 0) {
    Fail "Price must be greater than 0."
}

Write-Host "Input validation OK."
