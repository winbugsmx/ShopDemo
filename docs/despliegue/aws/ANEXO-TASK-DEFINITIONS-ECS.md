# Anexo — Task definitions ECS (ruta manual)

Plantillas para [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md). Sustituye:

- `<ACCOUNT_ID>`, `<AWS_REGION>`, `<ECR_URI>` (ej. `123456789.dkr.ecr.us-east-1.amazonaws.com`)
- `<EXEC_ROLE_ARN>` — rol `shopdemo-ecs-execution`
- En MCP: URLs reales de ALB Catalog/Analytics

Patrón común de secrets SSM en `secrets`:

```json
"secrets": [
  { "name": "ConnectionStrings__DefaultConnection", "valueFrom": "arn:aws:ssm:us-east-1:<ACCOUNT_ID>:parameter/shopdemo/pg-catalog" },
  { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:us-east-1:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" }
]
```

## Catalog

Archivo `ecs-catalog-task.json`:

```json
{
  "family": "shopdemo-catalog",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [
    {
      "name": "catalog-api",
      "image": "<ECR_URI>/shopdemo-catalog:latest",
      "essential": true,
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
        { "name": "EventHubs__Enabled", "value": "true" },
        { "name": "EventHubs__EventHubName", "value": "shopdemo-events" }
      ],
      "secrets": [
        { "name": "ConnectionStrings__DefaultConnection", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/pg-catalog" },
        { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-catalog",
          "awslogs-region": "<AWS_REGION>",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

## Inventory

Archivo `ecs-inventory-task.json` — añade secrets `pg-inventory`, `azurite-checkpoint` y env `EventHubs__ConsumerGroup`, `EventHubs__CheckpointContainerName`.

## Orders

Archivo `ecs-orders-task.json` — secrets `pg-orders`, `eh-connection`; env `InventoryApi__BaseUrl` = `http://inventory.shopdemo.local:8080`.

## Analytics

Archivo `ecs-analytics-task.json` — secrets `eh-connection`, `azurite-checkpoint`; env consumer `analytics-service`, container `analytics-checkpoints`.

## MCP

Archivo `ecs-mcp-task.json`:

```json
{
  "family": "shopdemo-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [
    {
      "name": "mcp-api",
      "image": "<ECR_URI>/shopdemo-mcp:latest",
      "essential": true,
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
        { "name": "ShopDemo__CatalogApiBaseUrl", "value": "http://<ALB_CATALOG_DNS>" },
        { "name": "ShopDemo__InventoryApiBaseUrl", "value": "http://inventory.shopdemo.local:8080" },
        { "name": "ShopDemo__AnalyticsApiBaseUrl", "value": "http://<ALB_ANALYTICS_DNS>" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-mcp",
          "awslogs-region": "<AWS_REGION>",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

> Fuente de verdad en el repo: `scripts/aws/Deploy-AwsShopDemo.ps1`.
