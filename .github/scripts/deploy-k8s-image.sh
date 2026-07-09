#!/usr/bin/env bash
# Update a Deployment image and wait for rollout (AKS / EKS).
set -euo pipefail

DEPLOYMENT="${1:?deployment name required}"
CONTAINER="${2:?container name required}"
IMAGE="${3:?full image reference required}"
NAMESPACE="${4:-shopdemo}"
TIMEOUT="${5:-300s}"

kubectl -n "$NAMESPACE" set image "deployment/$DEPLOYMENT" "$CONTAINER=$IMAGE"
kubectl -n "$NAMESPACE" rollout status "deployment/$DEPLOYMENT" --timeout="$TIMEOUT"

echo "Rollout OK: $DEPLOYMENT -> $IMAGE"
