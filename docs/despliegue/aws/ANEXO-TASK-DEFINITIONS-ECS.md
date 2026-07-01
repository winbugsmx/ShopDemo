# Anexo — Task definitions ECS (ruta CLI y Portal)

Plantillas **completas** para [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md) y [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md).

## Placeholders

| Placeholder | Ejemplo |
|---|---|
| `<ACCOUNT_ID>` | `905221885508` |
| `<AWS_REGION>` | `us-east-2` |
| `<ECR_URI>` | `905221885508.dkr.ecr.us-east-2.amazonaws.com` |
| `<EXEC_ROLE_ARN>` | `arn:aws:iam::905221885508:role/shopdemo-ecs-execution` |
| `<PG_IP>` | IP privada task Postgres (ej. `10.0.1.45`) |
| `<AZ_IP>` | IP privada task Azurite |
| `<ALB_CATALOG_DNS>` | DNS ALB Catalog (sin `http://`) |
| `<ALB_ANALYTICS_DNS>` | DNS ALB Analytics |

---

## 1. PostgreSQL (`shopdemo-postgres`)

```json
{
  "family": "shopdemo-postgres",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
    "name": "postgres",
    "image": "postgres:16-alpine",
    "essential": true,
    "portMappings": [{ "containerPort": 5432, "protocol": "tcp" }],
    "environment": [
      { "name": "POSTGRES_USER", "value": "ShopDemo" },
      { "name": "POSTGRES_PASSWORD", "value": "ShopDemo123!" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/shopdemo-postgres",
        "awslogs-region": "<AWS_REGION>",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

---

## 2. Azurite (`shopdemo-azurite`)

```json
{
  "family": "shopdemo-azurite",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
    "name": "azurite",
    "image": "mcr.microsoft.com/azure-storage/azurite",
    "essential": true,
    "command": ["azurite-blob", "--blobHost", "0.0.0.0", "--blobPort", "10000"],
    "portMappings": [{ "containerPort": 10000, "protocol": "tcp" }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/shopdemo-azurite",
        "awslogs-region": "<AWS_REGION>",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

---

## 3. Catalog (`shopdemo-catalog`)

```json
{
  "family": "shopdemo-catalog",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
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
  }]
}
```

---

## 4. Inventory (`shopdemo-inventory`)

```json
{
  "family": "shopdemo-inventory",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
    "name": "inventory-api",
    "image": "<ECR_URI>/shopdemo-inventory:latest",
    "essential": true,
    "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
    "environment": [
      { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
      { "name": "EventHubs__Enabled", "value": "true" },
      { "name": "EventHubs__EventHubName", "value": "shopdemo-events" },
      { "name": "EventHubs__ConsumerGroup", "value": "inventory-service" },
      { "name": "EventHubs__CheckpointContainerName", "value": "inventory-checkpoints" }
    ],
    "secrets": [
      { "name": "ConnectionStrings__DefaultConnection", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/pg-inventory" },
      { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" },
      { "name": "EventHubs__CheckpointStorageConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/azurite-checkpoint" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/shopdemo-inventory",
        "awslogs-region": "<AWS_REGION>",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

---

## 5. Orders (`shopdemo-orders`)

```json
{
  "family": "shopdemo-orders",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
    "name": "orders-api",
    "image": "<ECR_URI>/shopdemo-orders:latest",
    "essential": true,
    "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
    "environment": [
      { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
      { "name": "EventHubs__Enabled", "value": "true" },
      { "name": "EventHubs__EventHubName", "value": "shopdemo-events" },
      { "name": "InventoryApi__BaseUrl", "value": "http://inventory.shopdemo.local:8080" }
    ],
    "secrets": [
      { "name": "ConnectionStrings__DefaultConnection", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/pg-orders" },
      { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/shopdemo-orders",
        "awslogs-region": "<AWS_REGION>",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

---

## 6. Analytics (`shopdemo-analytics`)

```json
{
  "family": "shopdemo-analytics",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
    "name": "analytics-api",
    "image": "<ECR_URI>/shopdemo-analytics:latest",
    "essential": true,
    "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
    "environment": [
      { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
      { "name": "EventHubs__Enabled", "value": "true" },
      { "name": "EventHubs__EventHubName", "value": "shopdemo-events" },
      { "name": "EventHubs__ConsumerGroup", "value": "analytics-service" },
      { "name": "EventHubs__CheckpointContainerName", "value": "analytics-checkpoints" }
    ],
    "secrets": [
      { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" },
      { "name": "EventHubs__CheckpointStorageConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/azurite-checkpoint" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/shopdemo-analytics",
        "awslogs-region": "<AWS_REGION>",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

---

## 7. MCP Gateway (`shopdemo-mcp`)

> Crear **después** de tener DNS de ALB Catalog y Analytics.

```json
{
  "family": "shopdemo-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [{
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
  }]
}
```

---

## 8. SSM — valores finales (tras IPs reales)

| Parámetro | Valor (sustituir `<PG_IP>`, `<AZ_IP>`) |
|---|---|
| `/shopdemo/pg-catalog` | `Host=<PG_IP>;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123!` |
| `/shopdemo/pg-orders` | `Host=<PG_IP>;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123!` |
| `/shopdemo/pg-inventory` | `Host=<PG_IP>;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123!` |
| `/shopdemo/azurite-checkpoint` | `DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://<AZ_IP>:10000/devstoreaccount1;` |

---

## 9. Bases de datos PostgreSQL

Ejecutar contra la IP privada de Postgres (requiere `psql` local o task one-off):

```sql
CREATE DATABASE "ShopDemoCatalog";
CREATE DATABASE "ShopDemoOrders";
CREATE DATABASE "ShopDemoInventory";
```

```powershell
$env:PGPASSWORD = "ShopDemo123!"
psql -h <PG_IP> -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoCatalog";'
psql -h <PG_IP> -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoOrders";'
psql -h <PG_IP> -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoInventory";'
Remove-Item Env:PGPASSWORD
```
