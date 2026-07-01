#!/usr/bin/env bash
# Create/update shopdemo-secrets from GitHub Actions env (no secrets.yaml in repo).
set -euo pipefail

NAMESPACE="${K8S_NAMESPACE:-shopdemo}"
SECRET_NAME="${K8S_SECRET_NAME:-shopdemo-secrets}"

EH_CONN="${EVENT_HUBS_CONNECTION_STRING:-}"
PG_CATALOG="${PG_CATALOG_CONN:-}"
PG_ORDERS="${PG_ORDERS_CONN:-}"
PG_INVENTORY="${PG_INVENTORY_CONN:-}"
AZURITE="${AZURITE_CHECKPOINT_CONN:-DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://shopdemo-azurite:10000/devstoreaccount1;}"
PG_USER="${POSTGRES_USER:-ShopDemo}"
PG_PASS="${POSTGRES_PASSWORD:-ShopDemo123!}"

if [[ -z "$EH_CONN" ]]; then
  echo "Skip sync-k8s-secrets: EVENT_HUBS_CONNECTION_STRING not set"
  exit 0
fi

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl create secret generic "$SECRET_NAME" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml \
  --from-literal="POSTGRES_USER=$PG_USER" \
  --from-literal="POSTGRES_PASSWORD=$PG_PASS" \
  --from-literal="EVENT_HUBS_CONNECTION_STRING=$EH_CONN" \
  --from-literal="PG_CATALOG_CONN=$PG_CATALOG" \
  --from-literal="PG_ORDERS_CONN=$PG_ORDERS" \
  --from-literal="PG_INVENTORY_CONN=$PG_INVENTORY" \
  --from-literal="AZURITE_CHECKPOINT_CONN=$AZURITE" \
  | kubectl apply -f -

echo "Secret $SECRET_NAME updated in namespace $NAMESPACE"
