#!/usr/bin/env bash
# Apply ShopDemo k8s manifests (excludes secrets.yaml — use sync-k8s-secrets.sh).
set -euo pipefail

APPLY_INFRA="${APPLY_INFRA:-false}"
ROOT="${1:-k8s}"

apply_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "Applying $dir"
    kubectl apply -f "$dir"
  fi
}

if [[ -f "$ROOT/namespace.yaml" ]]; then
  echo "Applying $ROOT/namespace.yaml"
  kubectl apply -f "$ROOT/namespace.yaml"
fi

if [[ "$APPLY_INFRA" == "true" ]]; then
  apply_dir "$ROOT/postgres"
  apply_dir "$ROOT/azurite"
fi

apply_dir "$ROOT/catalog"
apply_dir "$ROOT/inventory"
apply_dir "$ROOT/orders"
apply_dir "$ROOT/analytics"
apply_dir "$ROOT/mcp"
apply_dir "$ROOT/catalog/hpa.yaml"
apply_dir "$ROOT/ingress"

echo "Manifests applied (APPLY_INFRA=$APPLY_INFRA)"
