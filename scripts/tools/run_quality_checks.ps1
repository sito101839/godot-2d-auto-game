param(
    [switch]$IncludeBalance
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Push-Location $projectRoot

try {
    & (Join-Path $PSScriptRoot "run_smoke_tests.ps1") -IncludeBalance:$IncludeBalance
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    git diff --check
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Write-Host "QUALITY_CHECK_PASS"
    exit 0
} finally {
    Pop-Location
}
