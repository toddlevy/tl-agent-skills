#!/usr/bin/env bash
# OpenMeter Local Dev — Verify Setup
# Checks that all services are running and configured correctly.
# Usage: bash verify-setup.sh

set -euo pipefail

PASS=0; FAIL=0; WARN=0
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

check_endpoint() {
    local name="$1" url="$2"
    if curl -sf --max-time 5 "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}[PASS]${NC} $name — $url"
        ((PASS++))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $name — $url"
        ((FAIL++))
        return 1
    fi
}

check_docker() {
    local name="$1"
    local status
    status=$(docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null || echo "not found")
    if [ "$status" = "running" ]; then
        echo -e "  ${GREEN}[PASS]${NC} Docker: $name is running"
        ((PASS++))
    else
        echo -e "  ${RED}[FAIL]${NC} Docker: $name is $status"
        ((FAIL++))
    fi
}

echo ""
echo -e "${CYAN}========================================"
echo -e " OpenMeter Local Dev — Health Check"
echo -e "========================================${NC}"
echo ""

# Docker containers
echo -e "${YELLOW}Docker Containers:${NC}"
# Update these container names to match your docker-compose.yml
for c in openmeter postgres-openmeter kafka clickhouse redis; do
    check_docker "$c"
done

echo ""

# OpenMeter API
echo -e "${YELLOW}OpenMeter API:${NC}"
check_endpoint "Meters endpoint" "http://localhost:8888/api/v1/meters" || true

# OpenMeter Apps
echo ""
echo -e "${YELLOW}OpenMeter Apps:${NC}"
apps_json=$(curl -sf --max-time 5 "http://localhost:8888/api/v1/apps" 2>/dev/null || echo "[]")
if echo "$apps_json" | grep -qi "stripe"; then
    if echo "$apps_json" | grep -qi "sandbox"; then
        echo -e "  ${YELLOW}[WARN]${NC} Both Stripe and Sandbox installed — remove Sandbox!"
        ((WARN++))
    else
        echo -e "  ${GREEN}[PASS]${NC} Stripe app installed, Sandbox removed"
        ((PASS++))
    fi
elif echo "$apps_json" | grep -qi "sandbox"; then
    echo -e "  ${YELLOW}[WARN]${NC} Only Sandbox app — install Stripe for real billing"
    ((WARN++))
else
    echo -e "  ${YELLOW}[WARN]${NC} No billing apps found"
    ((WARN++))
fi

echo ""

# Ngrok
echo -e "${YELLOW}Ngrok:${NC}"
ngrok_url=$(curl -sf --max-time 3 "http://127.0.0.1:4040/api/tunnels" 2>/dev/null | grep -oP '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
if [ -n "$ngrok_url" ]; then
    echo -e "  ${GREEN}[PASS]${NC} Ngrok active: $ngrok_url"
    ((PASS++))
else
    echo -e "  ${YELLOW}[WARN]${NC} Ngrok not running (only needed for Stripe billing)"
    ((WARN++))
fi

echo ""

# API Server
echo -e "${YELLOW}API Server:${NC}"
if curl -sf --max-time 3 "http://127.0.0.1:3001/" > /dev/null 2>&1 || curl -so /dev/null -w "%{http_code}" --max-time 3 "http://127.0.0.1:3001/" 2>/dev/null | grep -q "[0-9]"; then
    echo -e "  ${GREEN}[PASS]${NC} API server responding on :3001"
    ((PASS++))
else
    echo -e "  ${RED}[FAIL]${NC} API server not responding on :3001"
    ((FAIL++))
fi

echo ""
echo -e "${CYAN}========================================"
echo -e " Results: $PASS passed, $FAIL failed, $WARN warnings"
echo -e "========================================${NC}"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo -e "${RED}Fix failures before proceeding. See references/REFERENCE.md for troubleshooting.${NC}"
    exit 1
fi
