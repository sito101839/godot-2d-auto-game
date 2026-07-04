param(
    [switch]$IncludeBalance,
    [switch]$StopOnFailure
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$logDir = Join-Path $projectRoot ".godot\smoke_test_logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class NativeErrorMode {
    [DllImport("kernel32.dll")]
    public static extern uint SetErrorMode(uint uMode);
}
"@ -ErrorAction SilentlyContinue | Out-Null
    [NativeErrorMode]::SetErrorMode(0x0001 -bor 0x0002) | Out-Null
} catch {
    Write-Host "WARN crash dialog suppression unavailable: $($_.Exception.Message)"
}

$fatalPatterns = @(
    "SCRIPT ERROR",
    "Parser Error",
    "Parse Error",
    "Invalid call",
    "SMOKE_TEST_FAIL",
    "ERROR:"
)

$tests = @(
    @{ Name = "hello_world"; Script = "res://scripts/tools/hello_world_smoke_test.gd"; Marker = "SMOKE_TEST_PASS hello_world"; Optional = $false },
    @{ Name = "target_selection"; Script = "res://scripts/tools/target_selection_smoke_test.gd"; Marker = "SMOKE_TEST_PASS target_selection"; Optional = $false },
    @{ Name = "battle"; Script = "res://scripts/tools/battle_smoke_test.gd"; Marker = "SMOKE_TEST_PASS battle_result"; Optional = $false },
    @{ Name = "guild_progression"; Script = "res://scripts/tools/guild_progression_smoke_test.gd"; Marker = "SMOKE_TEST_PASS guild_progression"; Optional = $false },
    @{ Name = "guild_year_cycle"; Script = "res://scripts/tools/guild_year_cycle_smoke_test.gd"; Marker = "SMOKE_TEST_PASS guild_year_cycle"; Optional = $false },
    @{ Name = "guild_three_year"; Script = "res://scripts/tools/guild_three_year_smoke_test.gd"; Marker = "SMOKE_TEST_PASS guild_three_year_cycle"; Optional = $false },
    @{ Name = "ui_state"; Script = "res://scripts/tools/ui_state_smoke_test.gd"; Marker = "SMOKE_TEST_PASS ui_state"; Optional = $false },
    @{ Name = "beta_completion"; Script = "res://scripts/tools/beta_completion_smoke_test.gd"; Marker = "SMOKE_TEST_PASS beta_completion"; Optional = $false },
    @{ Name = "balance_sample"; Script = "res://scripts/tools/balance_sample_smoke_test.gd"; Marker = "SMOKE_TEST_PASS balance_sample"; Optional = $true }
)

function Invoke-LoggedProcess {
    param(
        [string]$FileName,
        [string[]]$Arguments,
        [string]$LogPath
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FileName
    foreach ($arg in $Arguments) {
        [void]$psi.ArgumentList.Add($arg)
    }
    $psi.WorkingDirectory = $projectRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    $combined = @($stdout, $stderr) -join "`n"
    Set-Content -LiteralPath $LogPath -Value $combined -Encoding UTF8

    return @{
        ExitCode = $process.ExitCode
        Output = $combined
    }
}

function Test-FatalOutput {
    param([string]$Output)

    foreach ($pattern in $fatalPatterns) {
        if ($Output.Contains($pattern)) {
            return $pattern
        }
    }
    return $null
}

$results = @()

$parseLog = Join-Path $logDir "parse_check.log"
$parse = Invoke-LoggedProcess -FileName "godot" -Arguments @("--headless", "--path", ".", "--quit") -LogPath $parseLog
$parseFatal = Test-FatalOutput -Output $parse.Output
$parsePassed = ($parse.ExitCode -eq 0 -and $null -eq $parseFatal)
$results += @{ Name = "parse_check"; Passed = $parsePassed; ExitCode = $parse.ExitCode; Log = $parseLog; Detail = $parseFatal }
Write-Host ("{0} parse_check" -f ($(if ($parsePassed) { "PASS" } else { "FAIL" })))
if (-not $parsePassed -and $StopOnFailure) {
    exit 1
}

foreach ($test in $tests) {
    if ($test.Optional -and -not $IncludeBalance) {
        continue
    }

    $logPath = Join-Path $logDir ("{0}.log" -f $test.Name)
    $args = @("--headless", "--path", ".", "--script", $test.Script, "--log-file", $logPath)
    $run = Invoke-LoggedProcess -FileName "godot" -Arguments $args -LogPath $logPath
    $fatal = Test-FatalOutput -Output $run.Output
    $hasMarker = $run.Output.Contains($test.Marker)
    $passed = ($hasMarker -and $null -eq $fatal)

    $results += @{ Name = $test.Name; Passed = $passed; ExitCode = $run.ExitCode; Log = $logPath; Detail = $fatal }
    Write-Host ("{0} {1}" -f ($(if ($passed) { "PASS" } else { "FAIL" })), $test.Name)
    if (-not $passed) {
        Write-Host "  marker: $($test.Marker)"
        Write-Host "  exit: $($run.ExitCode)"
        Write-Host "  log: $logPath"
        if ($fatal) {
            Write-Host "  fatal: $fatal"
        }
        if ($StopOnFailure) {
            exit 1
        }
    }
}

$failed = @($results | Where-Object { -not $_.Passed })
Write-Host ""
Write-Host ("Smoke summary: {0}/{1} passed" -f (($results.Count - $failed.Count)), $results.Count)

if ($failed.Count -gt 0) {
    exit 1
}

exit 0
