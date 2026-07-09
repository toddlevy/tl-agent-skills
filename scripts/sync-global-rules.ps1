<#
.SYNOPSIS
    Mirrors the canonical tl-* Cursor rules from this repo's rules/ folder into
    the Cursor-only global rules directory as a real COPY (not a symlink).

.DESCRIPTION
    Cursor discovers user-global rules only under ~/.cursor/rules/. Unlike
    tl-* skills -- which install into the cross-tool ~/.agents/skills/ store via
    `npx skills add` -- rules are a Cursor-proprietary concept and must land in
    ~/.cursor/rules/. This script copies rules/*.mdc from the canonical D: repo
    into ~/.cursor/rules/tl-agent-rules/ and prunes any stale files that no
    longer exist in the source (so a canonical rename does not leave an orphan
    behind under the old name).

    Canonical source (edit here) : <repo>/rules/
    Sync destination (read-only) : ~/.cursor/rules/tl-agent-rules/

    Cursor's local loader rejects reparse points that resolve outside its own
    tree, and a symlink silently couples the mirror to uncommitted D: edits, so
    the destination is a plain copied folder that this script keeps in sync.

.PARAMETER Strict
    Exit non-zero if the destination is out of sync with the source instead of
    reconciling it. Use in a pre-push / drift check.

.USAGE
    .\scripts\sync-global-rules.ps1
    .\scripts\sync-global-rules.ps1 -Strict
#>

[CmdletBinding()]
param(
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $RepoRoot "rules"
$DestDir = Join-Path $env:USERPROFILE ".cursor\rules\tl-agent-rules"

Write-Host "`n[TL-RULES] Canonical source : $SourceDir" -ForegroundColor DarkGray
Write-Host "[TL-RULES] Sync destination : $DestDir`n" -ForegroundColor DarkGray

if (-not (Test-Path -LiteralPath $SourceDir)) {
    Write-Host "[TL-RULES] Source rules/ folder not found: $SourceDir" -ForegroundColor Red
    exit 1
}

$sourceFiles = Get-ChildItem -LiteralPath $SourceDir -Filter *.mdc -File |
    Sort-Object Name

if ($sourceFiles.Count -eq 0) {
    Write-Host "[TL-RULES] No *.mdc rules found in source; nothing to sync." -ForegroundColor Yellow
    exit 0
}

# A pre-existing symlink/reparse point at the destination must be removed before
# a real folder can take its place.
if (Test-Path -LiteralPath $DestDir) {
    $destItem = Get-Item -LiteralPath $DestDir -Force
    if ($destItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "[TL-RULES] Destination is a reparse point ($($destItem.LinkType)); removing it to replace with a real copy." -ForegroundColor Yellow
        if ($Strict) {
            Write-Host "[TL-RULES] STRICT: destination is a symlink, not a copied folder." -ForegroundColor Red
            exit 2
        }
        cmd /c rmdir "`"$DestDir`"" | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $DestDir)) {
    if ($Strict) {
        Write-Host "[TL-RULES] STRICT: destination folder is missing." -ForegroundColor Red
        exit 2
    }
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

$drift = @()

# Copy / update every source rule.
foreach ($file in $sourceFiles) {
    $destPath = Join-Path $DestDir $file.Name
    $needsCopy = $true
    if (Test-Path -LiteralPath $destPath) {
        $srcHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $destPath -Algorithm SHA256).Hash
        $needsCopy = ($srcHash -ne $dstHash)
    }
    if ($needsCopy) {
        $drift += "update: $($file.Name)"
        if (-not $Strict) {
            Copy-Item -LiteralPath $file.FullName -Destination $destPath -Force
        }
    }
}

# Prune stale destination files not present in source (e.g. a renamed rule's
# old name).
$sourceNames = $sourceFiles.Name
$staleFiles = Get-ChildItem -LiteralPath $DestDir -Filter *.mdc -File |
    Where-Object { $sourceNames -notcontains $_.Name }

foreach ($stale in $staleFiles) {
    $drift += "prune: $($stale.Name)"
    if (-not $Strict) {
        Remove-Item -LiteralPath $stale.FullName -Force
    }
}

if ($drift.Count -gt 0) {
    if ($Strict) {
        Write-Host "[TL-RULES] STRICT: destination out of sync:" -ForegroundColor Red
        $drift | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 3
    }
    Write-Host "[TL-RULES] Reconciled:" -ForegroundColor Cyan
    $drift | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
}
else {
    Write-Host "[TL-RULES] Already in sync ($($sourceFiles.Count) rule(s))." -ForegroundColor Green
}

Write-Host "`n[TL-RULES] Done. $($sourceFiles.Count) rule(s) mirrored to ~/.cursor/rules/tl-agent-rules/." -ForegroundColor Green
