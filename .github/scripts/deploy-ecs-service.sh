#!/usr/bin/env bash
# Register a new ECS task definition revision (new image + env overrides) and update the service.
set -euo pipefail

TASK_FAMILY="${1:?task family required}"
CONTAINER_NAME="${2:?container name required}"
CLUSTER="${3:?cluster required}"
IMAGE="${4:?image uri required}"
REGION="${5:?region required}"

EH_NAME="${EVENT_HUB_NAME:-shopdemo-events}"

TASK_JSON=$(aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY" \
  --region "$REGION" \
  --query 'taskDefinition' \
  --output json)

NEW_TASK=$(echo "$TASK_JSON" | jq \
  --arg IMAGE "$IMAGE" \
  --arg CONTAINER "$CONTAINER_NAME" \
  --arg FAMILY "$TASK_FAMILY" \
  --arg EH_NAME "$EH_NAME" \
  --arg INV_URL "${INVENTORY_API_BASE_URL:-}" \
  --arg MCP_CAT "${MCP_CATALOG_URL:-}" \
  --arg MCP_INV "${MCP_INVENTORY_URL:-}" \
  --arg MCP_ANA "${MCP_ANALYTICS_URL:-}" \
  '
  del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)
  | .containerDefinitions = (
      .containerDefinitions
      | map(
          if .name == $CONTAINER then
            .image = $IMAGE
            | .environment = (
                (.environment // [])
                | map(select(
                    .name != "EventHubs__EventHubName"
                    and .name != "InventoryApi__BaseUrl"
                    and .name != "ShopDemo__CatalogApiBaseUrl"
                    and .name != "ShopDemo__InventoryApiBaseUrl"
                    and .name != "ShopDemo__AnalyticsApiBaseUrl"
                  ))
                + [{name: "EventHubs__EventHubName", value: $EH_NAME}]
                + (if ($FAMILY | endswith("-orders")) and $INV_URL != ""
                   then [{name: "InventoryApi__BaseUrl", value: $INV_URL}] else [] end)
                + (if ($FAMILY | endswith("-mcp")) and $MCP_CAT != ""
                   then [{name: "ShopDemo__CatalogApiBaseUrl", value: $MCP_CAT}] else [] end)
                + (if ($FAMILY | endswith("-mcp")) and $MCP_INV != ""
                   then [{name: "ShopDemo__InventoryApiBaseUrl", value: $MCP_INV}] else [] end)
                + (if ($FAMILY | endswith("-mcp")) and $MCP_ANA != ""
                   then [{name: "ShopDemo__AnalyticsApiBaseUrl", value: $MCP_ANA}] else [] end)
              )
          else .
          end
        )
    )
  ')

NEW_ARN=$(aws ecs register-task-definition \
  --region "$REGION" \
  --cli-input-json "$NEW_TASK" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$TASK_FAMILY" \
  --task-definition "$NEW_ARN" \
  --force-new-deployment \
  --region "$REGION" \
  --query 'service.serviceName' \
  --output text

echo "Deployed $TASK_FAMILY -> $NEW_ARN"
