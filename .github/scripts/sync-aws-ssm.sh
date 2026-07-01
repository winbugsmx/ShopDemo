#!/usr/bin/env bash
# Sync GitHub secrets into AWS SSM Parameter Store (used by ECS task definitions at runtime).
set -euo pipefail

PREFIX="${LAB_PREFIX:-shopdemo}"
REGION="${AWS_REGION:?AWS_REGION required}"

put_param() {
  local name="$1"
  local value="$2"
  [[ -z "$value" ]] && return 0
  aws ssm put-parameter \
    --name "$name" \
    --value "$value" \
    --type SecureString \
    --overwrite \
    --region "$REGION"
  echo "Updated $name"
}

put_param "/${PREFIX}/eh-connection" "${EVENT_HUBS_CONNECTION_STRING:-}"
put_param "/${PREFIX}/pg-catalog" "${PG_CATALOG_CONN:-}"
put_param "/${PREFIX}/pg-orders" "${PG_ORDERS_CONN:-}"
put_param "/${PREFIX}/pg-inventory" "${PG_INVENTORY_CONN:-}"
put_param "/${PREFIX}/azurite-checkpoint" "${AZURITE_CHECKPOINT_CONN:-}"
