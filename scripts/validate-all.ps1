#Requires -Version 5.1
<#
.SYNOPSIS
  Validate all skill directories that contain a SKILL.md.
.DESCRIPTION
  Requires: agentskills CLI (pip install skills-ref)
  Exit code: 0 if all pass, 1 if any fail.
#>

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsDir = Join-Path $repoRoot 'skills'
$failures = 0
$count = 0

Get-ChildItem -Path $skillsDir -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
  ForEach-Object {
    $name = $_.Name
    $count++

    Write-Host "Validating $name ..."
    agentskills validate $_.FullName

    if ($LASTEXITCODE -ne 0) {
      Write-Host "  ✗ $name FAILED" -ForegroundColor Red
      $failures++
    } else {
      Write-Host "  ✓ $name" -ForegroundColor Green
    }
    Write-Host ""
  }

Write-Host "---"
Write-Host "Validated $count skill(s), $failures failure(s)."

if ($failures -gt 0) {
  exit 1
}
