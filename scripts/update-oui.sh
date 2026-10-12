#!/usr/bin/env bash
# Regenerate app/src/main/assets/oui_vendors.txt from the IEEE MA-L registry.
#
# Usage:
#   bash scripts/update-oui.sh
#
# Requires: bash, curl, tr, sed, sort, awk  (standard on Ubuntu CI and macOS)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/../app/src/main/assets/oui_vendors.txt"
URL="https://standards-oui.ieee.org/oui/oui.txt"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# "28-6F-B9   (hex)		Nokia Shanghai Bell Co., Ltd." -> "28:6F:B9|Nokia Shanghai Bell Co., Ltd."
# A few historic prefixes are listed twice; keep the first one in sort order.
curl -fsSL "$URL" \
    | tr -d '\r' \
    | sed -nE 's/^([0-9A-F]{2})-([0-9A-F]{2})-([0-9A-F]{2})[[:space:]]+\(hex\)[[:space:]]+(.*[^[:space:]])[[:space:]]*$/\1:\2:\3|\4/p' \
    | LC_ALL=C sort \
    | awk -F'|' '!seen[$1]++' > "$tmp"

# Refuse to overwrite the database with a truncated or rejected download.
count="$(wc -l < "$tmp" | tr -d '[:space:]')"
if (( count < 30000 )); then
    echo "ERROR: only $count entries parsed; $OUT left unchanged." >&2
    exit 1
fi

cat "$tmp" > "$OUT"
echo "oui_vendors.txt: $count entries."
