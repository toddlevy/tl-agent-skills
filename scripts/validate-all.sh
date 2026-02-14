#!/usr/bin/env bash
set -euo pipefail

# Validate all skill directories that contain a SKILL.md.
# Requires: agentskills CLI (pip install skills-ref)
# Exit code: 0 if all pass, 1 if any fail.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
failures=0
count=0

for skill_dir in "$SKILLS_DIR"/*/SKILL.md; do
  dir="$(dirname "$skill_dir")"
  name="$(basename "$dir")"
  count=$((count + 1))

  echo "Validating $name ..."
  if agentskills validate "$dir"; then
    echo "  ✓ $name"
  else
    echo "  ✗ $name FAILED"
    failures=$((failures + 1))
  fi
  echo ""
done

echo "---"
echo "Validated $count skill(s), $failures failure(s)."

if [ "$failures" -gt 0 ]; then
  exit 1
fi
