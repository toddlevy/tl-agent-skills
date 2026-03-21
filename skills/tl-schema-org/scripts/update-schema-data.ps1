$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataDir = Join-Path $scriptDir "..\data"

$baseUrl = "https://schema.org/version/latest"
$docsUrl = "https://schema.org/docs"

$files = @(
    @{ Url = "$baseUrl/schemaorg-current-https-types.csv"; Name = "schemaorg-current-https-types.csv" }
    @{ Url = "$baseUrl/schemaorg-current-https-properties.csv"; Name = "schemaorg-current-https-properties.csv" }
    @{ Url = "$docsUrl/tree.jsonld"; Name = "tree.jsonld" }
    @{ Url = "$docsUrl/jsonldcontext.json"; Name = "jsonldcontext.json" }
)

Write-Host "Updating Schema.org data files..."
Write-Host "Target: $dataDir"
Write-Host ""

if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

foreach ($file in $files) {
    Write-Host "  Downloading $($file.Name)..."
    Invoke-WebRequest -Uri $file.Url -OutFile (Join-Path $dataDir $file.Name)
}

try {
    $versionPage = (Invoke-WebRequest -Uri "https://schema.org/version/latest").Content
    $versionMatch = [regex]::Match($versionPage, 'V(\d+\.\d+)')
    $dateMatch = [regex]::Match($versionPage, '(\d{4}-\d{2}-\d{2})')
    $versionNum = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "unknown" }
    $versionDate = if ($dateMatch.Success) { $dateMatch.Groups[1].Value } else { "unknown" }
} catch {
    $versionNum = "unknown"
    $versionDate = "unknown"
}

$today = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$versionContent = @"
$versionNum | $versionDate
Downloaded: $today
Source: https://schema.org/version/latest
"@

Set-Content -Path (Join-Path $dataDir "VERSION") -Value $versionContent

Write-Host ""
Write-Host "Done. Schema.org $versionNum ($versionDate)"
Write-Host "Files written to $dataDir"
