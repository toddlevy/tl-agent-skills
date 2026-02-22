# Knip Health Check — tl-knip
# Runs a tiered Knip analysis and reports issues by category.
# Usage: pwsh knip-check.ps1 [-Production] [-Strict]

param(
  [switch]$Production,
  [switch]$Strict
)

$Pass = 0; $Fail = 0; $Warn = 0

function Write-Pass($msg)  { Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail($msg)  { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn($msg)  { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Head($msg)  { Write-Host $msg -ForegroundColor Cyan }

Write-Host ""
Write-Head "========================================"
Write-Head " Knip Dead Code Check"
Write-Head "========================================"

# Check Knip is available
try {
  $version = npx knip --version 2>$null | Select-Object -First 1
  Write-Host "  Knip: $version" -ForegroundColor Cyan
} catch {
  Write-Fail "Knip not found. Run: npm install -D knip"
  exit 1
}

Write-Host ""

function Run-KnipCheck {
  param(
    [string]$Name,
    [string]$Flag,
    [int]$MaxIssues = 0
  )

  $args = @($Flag, '--reporter', 'compact')
  if ($Production) { $args += '--production' }

  $output = npx knip @args 2>$null
  $count = ($output | Where-Object { $_ -match '\S' } | Measure-Object).Count

  if ($count -eq 0) {
    Write-Pass "$Name — 0 issues"
    $script:Pass++
  } elseif ($MaxIssues -gt 0 -and $count -le $MaxIssues) {
    Write-Warn "$Name — $count issues (threshold: $MaxIssues)"
    $script:Warn++
  } else {
    Write-Fail "$Name — $count issues"
    $script:Fail++
  }
}

Write-Head "--- Dependency Check"
Run-KnipCheck -Name "Unused dependencies" -Flag "--dependencies"

Write-Host ""
Write-Head "--- Export Check"
Run-KnipCheck -Name "Unused exports" -Flag "--exports"

Write-Host ""
Write-Head "--- File Check"
Run-KnipCheck -Name "Unused files" -Flag "--files"

Write-Host ""
Write-Head "========================================"
Write-Host "  Results: " -NoNewline
Write-Host "$Pass passed" -ForegroundColor Green -NoNewline
Write-Host ", " -NoNewline
Write-Host "$Warn warnings" -ForegroundColor Yellow -NoNewline
Write-Host ", " -NoNewline
Write-Host "$Fail failed" -ForegroundColor Red
Write-Head "========================================"

if ($Fail -gt 0) {
  Write-Host ""
  Write-Host "  Run 'npx knip' for full details." -ForegroundColor Cyan
  Write-Host "  See: https://github.com/toddlevy/tl-agent-skills/tree/main/skills/tl-knip" -ForegroundColor Cyan
  Write-Host ""
  exit 1
}

Write-Host ""
exit 0
