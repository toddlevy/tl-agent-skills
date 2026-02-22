#!/usr/bin/env bash
# Knip Health Check — tl-knip
# Runs a tiered Knip analysis and reports issues by category.
# Usage: bash knip-check.sh [--production] [--strict]

set -euo pipefail

PASS=0; FAIL=0; WARN=0
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

PRODUCTION=false
STRICT=false

for arg in "$@"; do
  case $arg in
    --production) PRODUCTION=true ;;
    --strict) STRICT=true ;;
  esac
done

echo ""
echo -e "${CYAN}========================================"
echo -e " Knip Dead Code Check"
echo -e "========================================${NC}"

# Check Knip is available
if ! npx knip --version &>/dev/null; then
  echo -e "  ${RED}[FAIL]${NC} Knip not found. Run: npm install -D knip"
  exit 1
fi

KNIP_VERSION=$(npx knip --version 2>/dev/null | head -1)
echo -e "  ${CYAN}Knip:${NC} $KNIP_VERSION"
echo ""

run_check() {
  local name="$1"
  local flag="$2"
  local max="${3:-}"
  local args="$flag --reporter json"

  if [ "$PRODUCTION" = true ]; then
    args="$args --production"
  fi

  local output
  output=$(npx knip $args 2>/dev/null || true)

  local count=0
  if command -v jq &>/dev/null; then
    case $flag in
      --dependencies)  count=$(echo "$output" | jq '[.dependencies // {}, .devDependencies // {}] | map(keys | length) | add // 0') ;;
      --exports)        count=$(echo "$output" | jq '[.exports // {}, .types // {}] | map(keys | length) | add // 0') ;;
      --files)          count=$(echo "$output" | jq '.files | length // 0') ;;
    esac
  else
    output_text=$(npx knip $flag --reporter compact 2>/dev/null || true)
    count=$(echo "$output_text" | grep -c "^" || true)
  fi

  if [ "$count" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} $name — 0 issues"
    ((PASS++))
  elif [ -n "$max" ] && [ "$count" -le "$max" ]; then
    echo -e "  ${YELLOW}[WARN]${NC} $name — $count issues (threshold: $max)"
    ((WARN++))
  else
    echo -e "  ${RED}[FAIL]${NC} $name — $count issues"
    ((FAIL++))
  fi
}

echo -e "${CYAN}--- Dependency Check${NC}"
run_check "Unused dependencies" "--dependencies" ""

echo ""
echo -e "${CYAN}--- Export Check${NC}"
run_check "Unused exports" "--exports" ""

echo ""
echo -e "${CYAN}--- File Check${NC}"
run_check "Unused files" "--files" ""

echo ""
echo -e "${CYAN}========================================"
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${YELLOW}${WARN} warnings${NC}, ${RED}${FAIL} failed${NC}"
echo -e "========================================${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo -e "${CYAN}Run 'npx knip' for full details.${NC}"
  echo -e "${CYAN}See: https://github.com/toddlevy/tl-agent-skills/tree/main/skills/tl-knip${NC}"
  echo ""
  exit 1
fi

echo ""
exit 0
