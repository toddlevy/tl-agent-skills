#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data"

BASE_URL="https://schema.org/version/latest"
DOCS_URL="https://schema.org/docs"

FILES=(
  "$BASE_URL/schemaorg-current-https-types.csv"
  "$BASE_URL/schemaorg-current-https-properties.csv"
  "$DOCS_URL/tree.jsonld"
  "$DOCS_URL/jsonldcontext.json"
)

echo "Updating Schema.org data files..."
echo "Target: $DATA_DIR"
echo ""

mkdir -p "$DATA_DIR"

for url in "${FILES[@]}"; do
  filename=$(basename "$url")
  echo "  Downloading $filename..."
  curl -sL "$url" -o "$DATA_DIR/$filename"
done

VERSION_PAGE=$(curl -sL "https://schema.org/version/latest" | head -50)
VERSION_NUM=$(echo "$VERSION_PAGE" | grep -oP 'V\K[0-9]+\.[0-9]+' | head -1 || echo "unknown")
VERSION_DATE=$(echo "$VERSION_PAGE" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1 || echo "unknown")

cat > "$DATA_DIR/VERSION" <<EOF
$VERSION_NUM | $VERSION_DATE
Downloaded: $(date -u +%Y-%m-%d)
Source: https://schema.org/version/latest
EOF

echo ""
echo "Done. Schema.org $VERSION_NUM ($VERSION_DATE)"
echo "Files written to $DATA_DIR"
