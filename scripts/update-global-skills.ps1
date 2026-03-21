<#
.SYNOPSIS
    Pulls latest tl-agent-skills from skills.sh into ~/.agents/skills only.
    Does NOT copy to individual agent directories (Cursor, Cline, Warp, etc.).
.USAGE
    .\scripts\update-global-skills.ps1
#>

$ErrorActionPreference = "Stop"

$SkillsPackage = "toddlevy/tl-agent-skills"
$TargetAgent = "universal"

Write-Host "`n[TL-SKILLS] Updating global skills from $SkillsPackage..." -ForegroundColor Cyan
Write-Host "[TL-SKILLS] Target: ~/.agents/skills (universal only, no agent copies)`n" -ForegroundColor DarkGray

npx skills add $SkillsPackage -g -y --agent $TargetAgent

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[TL-SKILLS] Update failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`n[TL-SKILLS] Done. Skills updated in ~/.agents/skills only." -ForegroundColor Green
