#!/usr/bin/env bash
# Apply GitHub secrets to an Azure Container App (runtime env vars, not baked into image).
set -euo pipefail

SERVICE="${1:?service name required}"
CONTAINER_APP="${2:?container app name required}"
RESOURCE_GROUP="${3:?resource group required}"
IMAGE="${4:?full image reference required}"

EH_CONN="${EVENT_HUBS_CONNECTION_STRING:-}"
EH_NAME="${EVENT_HUB_NAME:-shopdemo-events}"
STORAGE_CHECKPOINT="${STORAGE_CHECKPOINT_CONN:-}"

set_secrets() {
  local -a args=()
  [[ -n "$EH_CONN" ]] && args+=("eh-connection=$EH_CONN")
  case "$SERVICE" in
    catalog)
      [[ -n "${PG_CATALOG_CONN:-}" ]] && args+=("pg-catalog-conn=$PG_CATALOG_CONN")
      ;;
    orders)
      [[ -n "${PG_ORDERS_CONN:-}" ]] && args+=("pg-orders-conn=$PG_ORDERS_CONN")
      ;;
    inventory)
      [[ -n "${PG_INVENTORY_CONN:-}" ]] && args+=("pg-inventory-conn=$PG_INVENTORY_CONN")
      [[ -n "$STORAGE_CHECKPOINT" ]] && args+=("storage-checkpoint=$STORAGE_CHECKPOINT")
      ;;
    analytics)
      [[ -n "$STORAGE_CHECKPOINT" ]] && args+=("storage-checkpoint=$STORAGE_CHECKPOINT")
      ;;
  esac
  if ((${#args[@]})); then
    az containerapp secret set \
      --name "$CONTAINER_APP" \
      --resource-group "$RESOURCE_GROUP" \
      --secrets "${args[@]}"
  fi
}

set_env_vars() {
  local -a args=("ASPNETCORE_ENVIRONMENT=Production")
  case "$SERVICE" in
    catalog)
      args+=(
        "EventHubs__Enabled=true"
        "EventHubs__EventHubName=$EH_NAME"
      )
      [[ -n "$EH_CONN" ]] && args+=("EventHubs__ConnectionString=secretref:eh-connection")
      [[ -n "${PG_CATALOG_CONN:-}" ]] && args+=("ConnectionStrings__DefaultConnection=secretref:pg-catalog-conn")
      ;;
    orders)
      args+=(
        "EventHubs__Enabled=true"
        "EventHubs__EventHubName=$EH_NAME"
      )
      [[ -n "$EH_CONN" ]] && args+=("EventHubs__ConnectionString=secretref:eh-connection")
      [[ -n "${PG_ORDERS_CONN:-}" ]] && args+=("ConnectionStrings__DefaultConnection=secretref:pg-orders-conn")
      [[ -n "${INVENTORY_API_BASE_URL:-}" ]] && args+=("InventoryApi__BaseUrl=$INVENTORY_API_BASE_URL")
      ;;
    inventory)
      args+=(
        "EventHubs__Enabled=true"
        "EventHubs__EventHubName=$EH_NAME"
        "EventHubs__ConsumerGroup=inventory-service"
        "EventHubs__CheckpointContainerName=inventory-checkpoints"
      )
      [[ -n "$EH_CONN" ]] && args+=("EventHubs__ConnectionString=secretref:eh-connection")
      [[ -n "${PG_INVENTORY_CONN:-}" ]] && args+=("ConnectionStrings__DefaultConnection=secretref:pg-inventory-conn")
      [[ -n "$STORAGE_CHECKPOINT" ]] && args+=("EventHubs__CheckpointStorageConnectionString=secretref:storage-checkpoint")
      ;;
    analytics)
      args+=(
        "EventHubs__Enabled=true"
        "EventHubs__EventHubName=$EH_NAME"
        "EventHubs__ConsumerGroup=analytics-service"
        "EventHubs__CheckpointContainerName=analytics-checkpoints"
      )
      [[ -n "$EH_CONN" ]] && args+=("EventHubs__ConnectionString=secretref:eh-connection")
      [[ -n "$STORAGE_CHECKPOINT" ]] && args+=("EventHubs__CheckpointStorageConnectionString=secretref:storage-checkpoint")
      ;;
    mcp)
      [[ -n "${MCP_CATALOG_URL:-}" ]] && args+=("ShopDemo__CatalogApiBaseUrl=$MCP_CATALOG_URL")
      [[ -n "${MCP_INVENTORY_URL:-}" ]] && args+=("ShopDemo__InventoryApiBaseUrl=$MCP_INVENTORY_URL")
      [[ -n "${MCP_ANALYTICS_URL:-}" ]] && args+=("ShopDemo__AnalyticsApiBaseUrl=$MCP_ANALYTICS_URL")
      ;;
  esac
  az containerapp update \
    --name "$CONTAINER_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --image "$IMAGE" \
    --set-env-vars "${args[@]}"
}

set_secrets
set_env_vars
