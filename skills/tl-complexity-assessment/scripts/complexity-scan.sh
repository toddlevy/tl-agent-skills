#!/bin/bash
# Complexity Assessment Scanner
# Automated discovery of complexity hotspots in TypeScript/JavaScript codebases

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
TARGET_DIR="${1:-.}"
OUTPUT_FILE="${2:-complexity-report.md}"
LARGE_FILE_THRESHOLD=300
HUGE_FILE_THRESHOLD=500
HIGH_EXPORT_THRESHOLD=10
HIGH_IMPORT_THRESHOLD=15

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Complexity Assessment Scanner        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Target: $TARGET_DIR"
echo "Output: $OUTPUT_FILE"
echo ""

# Initialize report
cat > "$OUTPUT_FILE" << EOF
# Complexity Assessment Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Target:** $TARGET_DIR

---

EOF

# Function to add section to report
add_section() {
    echo -e "\n## $1\n" >> "$OUTPUT_FILE"
}

add_subsection() {
    echo -e "\n### $1\n" >> "$OUTPUT_FILE"
}

# ============================================
# SECTION 1: Large Files
# ============================================
echo -e "${YELLOW}[1/6] Scanning for large files...${NC}"
add_section "Large Files (>$LARGE_FILE_THRESHOLD lines)"

echo "| File | Lines | Severity |" >> "$OUTPUT_FILE"
echo "|------|-------|----------|" >> "$OUTPUT_FILE"

find "$TARGET_DIR" \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.next/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -type f -print0 2>/dev/null | \
while IFS= read -r -d '' file; do
    lines=$(wc -l < "$file")
    if [ "$lines" -gt "$HUGE_FILE_THRESHOLD" ]; then
        echo "| \`$file\` | $lines | 🔴 Critical |" >> "$OUTPUT_FILE"
    elif [ "$lines" -gt "$LARGE_FILE_THRESHOLD" ]; then
        echo "| \`$file\` | $lines | 🟡 Warning |" >> "$OUTPUT_FILE"
    fi
done

echo -e "${GREEN}  ✓ Large file scan complete${NC}"

# ============================================
# SECTION 2: High Export Count
# ============================================
echo -e "${YELLOW}[2/6] Analyzing exports per file...${NC}"
add_section "High Export Count (>$HIGH_EXPORT_THRESHOLD exports)"

echo "| File | Exports | Severity |" >> "$OUTPUT_FILE"
echo "|------|---------|----------|" >> "$OUTPUT_FILE"

if command -v rg &> /dev/null; then
    rg "^export " --type ts --type tsx -c "$TARGET_DIR" 2>/dev/null | \
    while IFS=: read -r file count; do
        if [ "$count" -gt "$HIGH_EXPORT_THRESHOLD" ]; then
            severity="🟡 Warning"
            [ "$count" -gt 20 ] && severity="🔴 Critical"
            echo "| \`$file\` | $count | $severity |" >> "$OUTPUT_FILE"
        fi
    done
else
    echo "*ripgrep (rg) not installed - skipping export analysis*" >> "$OUTPUT_FILE"
fi

echo -e "${GREEN}  ✓ Export analysis complete${NC}"

# ============================================
# SECTION 3: High Import Count
# ============================================
echo -e "${YELLOW}[3/6] Analyzing imports per file...${NC}"
add_section "High Import Count (>$HIGH_IMPORT_THRESHOLD imports)"

echo "| File | Imports | Severity |" >> "$OUTPUT_FILE"
echo "|------|---------|----------|" >> "$OUTPUT_FILE"

if command -v rg &> /dev/null; then
    rg "^import " --type ts --type tsx -c "$TARGET_DIR" 2>/dev/null | \
    while IFS=: read -r file count; do
        if [ "$count" -gt "$HIGH_IMPORT_THRESHOLD" ]; then
            severity="🟡 Warning"
            [ "$count" -gt 25 ] && severity="🔴 Critical"
            echo "| \`$file\` | $count | $severity |" >> "$OUTPUT_FILE"
        fi
    done
else
    echo "*ripgrep (rg) not installed - skipping import analysis*" >> "$OUTPUT_FILE"
fi

echo -e "${GREEN}  ✓ Import analysis complete${NC}"

# ============================================
# SECTION 4: God Files
# ============================================
echo -e "${YELLOW}[4/6] Detecting god files...${NC}"
add_section "Potential God Files"

echo "| File | Pattern | Risk |" >> "$OUTPUT_FILE"
echo "|------|---------|------|" >> "$OUTPUT_FILE"

for pattern in "utils.ts" "helpers.ts" "common.ts" "shared.ts" "index.ts"; do
    find "$TARGET_DIR" -name "$pattern" \
        -not -path "*/node_modules/*" \
        -not -path "*/.next/*" \
        -type f 2>/dev/null | \
    while read -r file; do
        lines=$(wc -l < "$file")
        if [ "$lines" -gt 100 ]; then
            echo "| \`$file\` | $pattern ($lines lines) | 🟡 Review |" >> "$OUTPUT_FILE"
        fi
    done
done

echo -e "${GREEN}  ✓ God file detection complete${NC}"

# ============================================
# SECTION 5: React Hook Complexity
# ============================================
echo -e "${YELLOW}[5/6] Analyzing React hook usage...${NC}"
add_section "React Components with Multiple Hooks"

echo "| File | useEffect | useState | Total | Severity |" >> "$OUTPUT_FILE"
echo "|------|-----------|----------|-------|----------|" >> "$OUTPUT_FILE"

if command -v rg &> /dev/null; then
    find "$TARGET_DIR" \( -name "*.tsx" -o -name "*.jsx" \) \
        -not -path "*/node_modules/*" \
        -type f 2>/dev/null | \
    while read -r file; do
        effects=$(rg -c "useEffect\(" "$file" 2>/dev/null || echo "0")
        states=$(rg -c "useState\(" "$file" 2>/dev/null || echo "0")
        total=$((effects + states))
        
        if [ "$total" -gt 5 ]; then
            severity="🟡 Warning"
            [ "$total" -gt 8 ] && severity="🔴 Critical"
            echo "| \`$file\` | $effects | $states | $total | $severity |" >> "$OUTPUT_FILE"
        fi
    done
fi

echo -e "${GREEN}  ✓ React hook analysis complete${NC}"

# ============================================
# SECTION 6: Circular Dependencies (if madge available)
# ============================================
echo -e "${YELLOW}[6/6] Checking for circular dependencies...${NC}"
add_section "Circular Dependencies"

if command -v madge &> /dev/null; then
    circulars=$(madge --circular "$TARGET_DIR" 2>/dev/null)
    if [ -n "$circulars" ]; then
        echo '```' >> "$OUTPUT_FILE"
        echo "$circulars" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    else
        echo "✅ No circular dependencies detected" >> "$OUTPUT_FILE"
    fi
else
    echo "*madge not installed - run \`npm i -g madge\` for circular dependency detection*" >> "$OUTPUT_FILE"
fi

echo -e "${GREEN}  ✓ Circular dependency check complete${NC}"

# ============================================
# Summary
# ============================================
add_section "Next Steps"

cat >> "$OUTPUT_FILE" << 'EOF'
1. Review 🔴 Critical findings first
2. For each finding, identify distinct responsibilities
3. Plan refactoring using strategies from `references/refactoring-strategies.md`
4. Address in order of ROI (high severity + low effort first)

See the main SKILL.md for the full assessment methodology.
EOF

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Scan Complete!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Report saved to: $OUTPUT_FILE"
