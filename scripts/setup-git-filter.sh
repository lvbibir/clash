#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

git config filter.mihomo-secrets.clean "python3 scripts/mihomo_git_filter.py clean"
git config filter.mihomo-secrets.smudge "python3 scripts/mihomo_git_filter.py smudge"
git config filter.mihomo-secrets.required true

echo "Git filter installed: mihomo-secrets"
echo "Commit will redact: secret, proxy-providers.*.url"
echo "If mihomo.yaml was already tracked, run: git add --renormalize \"mihomo.yaml\""
