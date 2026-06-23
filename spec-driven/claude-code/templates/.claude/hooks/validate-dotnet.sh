#!/usr/bin/env bash
# Pre-tool hook: validate dotnet build after C# edits (optional lightweight check)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! command -v dotnet >/dev/null 2>&1; then
  exit 0
fi

dotnet build ShopDemo.slnx --no-restore -v q 2>/dev/null || dotnet build ShopDemo.slnx -v q
