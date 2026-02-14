# OpenMeter Local Dev — Verify Setup
# Checks that all services are running and configured correctly.
# Usage: .\verify-setup.ps1

$ErrorActionPreference = "Continue"
$pass = 0
$fail = 0
$warn = 0

function Test-Endpoint {
    param([string]$Name, [string]$Url, [string]$Expect)
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  [PASS] $Name — $Url" -ForegroundColor Green
        $script:pass++
        return $true
    } catch {
        Write-Host "  [FAIL] $Name — $Url" -ForegroundColor Red
        Write-Host "         $($_.Exception.Message)" -ForegroundColor DarkRed
        $script:fail++
        return $false
    }
}

function Test-Docker {
    param([string]$ContainerName)
    try {
        $status = docker inspect --format '{{.State.Status}}' $ContainerName 2>$null
        if ($status -eq "running") {
            Write-Host "  [PASS] Docker: $ContainerName is running" -ForegroundColor Green
            $script:pass++
            return $true
        } else {
            Write-Host "  [FAIL] Docker: $ContainerName is $status" -ForegroundColor Red
            $script:fail++
            return $false
        }
    } catch {
        Write-Host "  [FAIL] Docker: $ContainerName not found" -ForegroundColor Red
        $script:fail++
        return $false
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " OpenMeter Local Dev — Health Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Docker containers ---
Write-Host "Docker Containers:" -ForegroundColor Yellow
$containers = @(
    # Update these container names to match your docker-compose.yml
    "openmeter",
    "postgres-openmeter",
    "kafka",
    "clickhouse",
    "redis"
)
foreach ($c in $containers) {
    Test-Docker $c | Out-Null
}

Write-Host ""

# --- OpenMeter API ---
Write-Host "OpenMeter API:" -ForegroundColor Yellow
Test-Endpoint "Meters endpoint" "http://localhost:8888/api/v1/meters" | Out-Null

# --- OpenMeter Apps ---
Write-Host ""
Write-Host "OpenMeter Apps:" -ForegroundColor Yellow
try {
    $apps = Invoke-RestMethod -Uri "http://localhost:8888/api/v1/apps" -Method Get -TimeoutSec 5
    $appList = if ($apps -is [array]) { $apps } else { @($apps) }
    $hasStripe = $false
    $hasSandbox = $false
    foreach ($app in $appList) {
        $appType = if ($app.type) { $app.type } elseif ($app.listing -and $app.listing.type) { $app.listing.type } else { "unknown" }
        if ($appType -match "stripe") { $hasStripe = $true }
        if ($appType -match "sandbox") { $hasSandbox = $true }
        Write-Host "  Found app: $($app.name) (type: $appType)" -ForegroundColor Gray
    }
    if ($hasStripe -and -not $hasSandbox) {
        Write-Host "  [PASS] Stripe app installed, Sandbox removed" -ForegroundColor Green
        $pass++
    } elseif ($hasStripe -and $hasSandbox) {
        Write-Host "  [WARN] Both Stripe and Sandbox installed — remove Sandbox!" -ForegroundColor DarkYellow
        $warn++
    } elseif ($hasSandbox) {
        Write-Host "  [WARN] Only Sandbox app — install Stripe for real billing" -ForegroundColor DarkYellow
        $warn++
    } else {
        Write-Host "  [WARN] No billing apps found" -ForegroundColor DarkYellow
        $warn++
    }
} catch {
    Write-Host "  [FAIL] Cannot reach /api/v1/apps" -ForegroundColor Red
    $fail++
}

Write-Host ""

# --- Ngrok ---
Write-Host "Ngrok:" -ForegroundColor Yellow
try {
    $tunnels = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -Method Get -TimeoutSec 3
    $publicUrl = $tunnels.tunnels[0].public_url
    Write-Host "  [PASS] Ngrok active: $publicUrl" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  [WARN] Ngrok not running (only needed for Stripe billing)" -ForegroundColor DarkYellow
    $warn++
}

Write-Host ""

# --- API Server ---
Write-Host "API Server:" -ForegroundColor Yellow
try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:3001/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  [PASS] API server responding on :3001" -ForegroundColor Green
    $pass++
} catch {
    try {
        # Some servers don't have /health — try root
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:3001/" -Method Get -TimeoutSec 3 -ErrorAction Stop
        Write-Host "  [PASS] API server responding on :3001" -ForegroundColor Green
        $pass++
    } catch {
        if ($_.Exception.Response) {
            # Got an HTTP response (even if error) — server is running
            Write-Host "  [PASS] API server responding on :3001 (HTTP $($_.Exception.Response.StatusCode))" -ForegroundColor Green
            $pass++
        } else {
            Write-Host "  [FAIL] API server not responding on :3001" -ForegroundColor Red
            $fail++
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Results: $pass passed, $fail failed, $warn warnings" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "Fix failures before proceeding. See references/REFERENCE.md for troubleshooting." -ForegroundColor Red
    exit 1
}
