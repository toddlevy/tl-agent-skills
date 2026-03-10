# Complexity Assessment Scanner
# Automated discovery of complexity hotspots in TypeScript/JavaScript codebases

param(
    [string]$TargetDir = ".",
    [string]$OutputFile = "complexity-report.md",
    [int]$LargeFileThreshold = 300,
    [int]$HugeFileThreshold = 500,
    [int]$HighExportThreshold = 10,
    [int]$HighImportThreshold = 15
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   Complexity Assessment Scanner        ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "Target: $TargetDir"
Write-Host "Output: $OutputFile"
Write-Host ""

# Initialize report
$reportContent = @"
# Complexity Assessment Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Target:** $TargetDir

---

"@

# ============================================
# SECTION 1: Large Files
# ============================================
Write-Host "[1/6] Scanning for large files..." -ForegroundColor Yellow

$reportContent += "`n## Large Files (>$LargeFileThreshold lines)`n`n"
$reportContent += "| File | Lines | Severity |`n"
$reportContent += "|------|-------|----------|`n"

$extensions = @("*.ts", "*.tsx", "*.js", "*.jsx")
$excludeDirs = @("node_modules", ".next", "dist", "build")

foreach ($ext in $extensions) {
    Get-ChildItem -Path $TargetDir -Filter $ext -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { 
        $path = $_.FullName
        -not ($excludeDirs | Where-Object { $path -like "*\$_\*" })
    } |
    ForEach-Object {
        $lines = (Get-Content $_.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        $relativePath = $_.FullName.Replace((Get-Location).Path, "").TrimStart("\", "/")
        
        if ($lines -gt $HugeFileThreshold) {
            $reportContent += "| ``$relativePath`` | $lines | 🔴 Critical |`n"
        }
        elseif ($lines -gt $LargeFileThreshold) {
            $reportContent += "| ``$relativePath`` | $lines | 🟡 Warning |`n"
        }
    }
}

Write-Host "  ✓ Large file scan complete" -ForegroundColor Green

# ============================================
# SECTION 2: High Export Count
# ============================================
Write-Host "[2/6] Analyzing exports per file..." -ForegroundColor Yellow

$reportContent += "`n## High Export Count (>$HighExportThreshold exports)`n`n"
$reportContent += "| File | Exports | Severity |`n"
$reportContent += "|------|---------|----------|`n"

$rgAvailable = Get-Command rg -ErrorAction SilentlyContinue

if ($rgAvailable) {
    $exportResults = rg "^export " --type ts -c $TargetDir 2>$null
    foreach ($line in $exportResults) {
        if ($line -match "(.+):(\d+)$") {
            $file = $matches[1]
            $count = [int]$matches[2]
            
            if ($count -gt $HighExportThreshold) {
                $severity = if ($count -gt 20) { "🔴 Critical" } else { "🟡 Warning" }
                $reportContent += "| ``$file`` | $count | $severity |`n"
            }
        }
    }
}
else {
    $reportContent += "*ripgrep (rg) not installed - skipping export analysis*`n"
}

Write-Host "  ✓ Export analysis complete" -ForegroundColor Green

# ============================================
# SECTION 3: High Import Count
# ============================================
Write-Host "[3/6] Analyzing imports per file..." -ForegroundColor Yellow

$reportContent += "`n## High Import Count (>$HighImportThreshold imports)`n`n"
$reportContent += "| File | Imports | Severity |`n"
$reportContent += "|------|---------|----------|`n"

if ($rgAvailable) {
    $importResults = rg "^import " --type ts -c $TargetDir 2>$null
    foreach ($line in $importResults) {
        if ($line -match "(.+):(\d+)$") {
            $file = $matches[1]
            $count = [int]$matches[2]
            
            if ($count -gt $HighImportThreshold) {
                $severity = if ($count -gt 25) { "🔴 Critical" } else { "🟡 Warning" }
                $reportContent += "| ``$file`` | $count | $severity |`n"
            }
        }
    }
}
else {
    $reportContent += "*ripgrep (rg) not installed - skipping import analysis*`n"
}

Write-Host "  ✓ Import analysis complete" -ForegroundColor Green

# ============================================
# SECTION 4: God Files
# ============================================
Write-Host "[4/6] Detecting god files..." -ForegroundColor Yellow

$reportContent += "`n## Potential God Files`n`n"
$reportContent += "| File | Pattern | Risk |`n"
$reportContent += "|------|---------|------|`n"

$godPatterns = @("utils.ts", "helpers.ts", "common.ts", "shared.ts")

foreach ($pattern in $godPatterns) {
    Get-ChildItem -Path $TargetDir -Filter $pattern -Recurse -ErrorAction SilentlyContinue |
    Where-Object { 
        $path = $_.FullName
        -not ($excludeDirs | Where-Object { $path -like "*\$_\*" })
    } |
    ForEach-Object {
        $lines = (Get-Content $_.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        $relativePath = $_.FullName.Replace((Get-Location).Path, "").TrimStart("\", "/")
        
        if ($lines -gt 100) {
            $reportContent += "| ``$relativePath`` | $pattern ($lines lines) | 🟡 Review |`n"
        }
    }
}

Write-Host "  ✓ God file detection complete" -ForegroundColor Green

# ============================================
# SECTION 5: React Hook Complexity
# ============================================
Write-Host "[5/6] Analyzing React hook usage..." -ForegroundColor Yellow

$reportContent += "`n## React Components with Multiple Hooks`n`n"
$reportContent += "| File | useEffect | useState | Total | Severity |`n"
$reportContent += "|------|-----------|----------|-------|----------|`n"

if ($rgAvailable) {
    Get-ChildItem -Path $TargetDir -Include "*.tsx", "*.jsx" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { 
        $path = $_.FullName
        -not ($excludeDirs | Where-Object { $path -like "*\$_\*" })
    } |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $effects = ([regex]::Matches($content, "useEffect\(")).Count
        $states = ([regex]::Matches($content, "useState\(")).Count
        $total = $effects + $states
        
        if ($total -gt 5) {
            $relativePath = $_.FullName.Replace((Get-Location).Path, "").TrimStart("\", "/")
            $severity = if ($total -gt 8) { "🔴 Critical" } else { "🟡 Warning" }
            $reportContent += "| ``$relativePath`` | $effects | $states | $total | $severity |`n"
        }
    }
}

Write-Host "  ✓ React hook analysis complete" -ForegroundColor Green

# ============================================
# SECTION 6: Circular Dependencies
# ============================================
Write-Host "[6/6] Checking for circular dependencies..." -ForegroundColor Yellow

$reportContent += "`n## Circular Dependencies`n`n"

$madgeAvailable = Get-Command madge -ErrorAction SilentlyContinue

if ($madgeAvailable) {
    $circulars = madge --circular $TargetDir 2>$null
    if ($circulars) {
        $reportContent += "```````n"
        $reportContent += $circulars -join "`n"
        $reportContent += "`n```````n"
    }
    else {
        $reportContent += "✅ No circular dependencies detected`n"
    }
}
else {
    $reportContent += "*madge not installed - run ``npm i -g madge`` for circular dependency detection*`n"
}

Write-Host "  ✓ Circular dependency check complete" -ForegroundColor Green

# ============================================
# Summary
# ============================================
$reportContent += @"

## Next Steps

1. Review 🔴 Critical findings first
2. For each finding, identify distinct responsibilities
3. Plan refactoring using strategies from ``references/refactoring-strategies.md``
4. Address in order of ROI (high severity + low effort first)

See the main SKILL.md for the full assessment methodology.
"@

# Write report
$reportContent | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Scan Complete!                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Report saved to: $OutputFile"
