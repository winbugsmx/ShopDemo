#!/usr/bin/env bash
# Apply ShopDemo k8s manifests (excludes secrets.yaml — use sync-k8s-secrets.sh).
#
# Usage:
#   apply-k8s-manifests.sh [base_dir] [cloud]
#
# cloud: azure | aws | local (default: aws for backward compatibility in EKS workflow)
#   - Shared: namespace, postgres, azurite, services, ingress, HPA
#   - Deployments: k8s/<cloud>/<service>/deployment.yaml
set -euo pipefail

ROOT="${1:-k8s}"
CLOUD="${2:-aws}"
APPLY_INFRA="${APPLY_INFRA:-false}"

apply_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "Applying $dir"
    kubectl apply -f "$dir"
  fi
}

apply_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    echo "Applying $file"
    kubectl apply -f "$file"
  fi
}

if [[ ! "$CLOUD" =~ ^(azure|aws|local)$ ]]; then
  echo "Invalid cloud '$CLOUD'. Use: azure, aws, or local" >&2
  exit 1
fi

if [[ -f "$ROOT/namespace.yaml" ]]; then
  apply_file "$ROOT/namespace.yaml"
fi

if [[ "$APPLY_INFRA" == "true" ]]; then
  apply_dir "$ROOT/postgres"
  apply_dir "$ROOT/azurite"
fi

for svc in catalog inventory orders analytics mcp; do
  apply_dir "$ROOT/$svc"
  apply_file "$ROOT/$CLOUD/$svc/deployment.yaml"
done

apply_file "$ROOT/catalog/hpa.yaml"
apply_dir "$ROOT/ingress"

echo "Manifests applied (CLOUD=$CLOUD, APPLY_INFRA=$APPLY_INFRA)"
