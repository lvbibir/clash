#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIN_DIR="/mnt/d/software/1-portable/mihomo"
FILES=("mihomo.yaml" "mihomo-manager.ps1")

if [[ ! -d "$WIN_DIR" ]]; then
  echo "Windows directory not accessible: $WIN_DIR" >&2
  exit 1
fi

for file in "${FILES[@]}"; do
  src="$WIN_DIR/$file"
  dest="$REPO_DIR/$file"
  if [[ ! -f "$src" ]]; then
    echo "Skip: source file missing -> $src" >&2
    continue
  fi
  cp -av "$src" "$dest"
done

target="$REPO_DIR/mihomo.yaml"
if [[ -f "$target" ]]; then
python3 - "$target" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()
inside = False

for idx, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("proxy-providers:"):
        inside = True
        continue
    if inside and stripped and not line.startswith(" "):
        inside = False
    if inside and "url:" in line:
        prefix = line.split("url:", 1)[0]
        lines[idx] = f"{prefix}url: '---'"

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
fi

echo "Sync complete."
