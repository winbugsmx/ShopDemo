# Guía — Release Azure con Azure CLI (manual)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Tiempo estimado** | 6–10 h (sin script) |
| **Cuándo usar** | Aprender cada recurso; el script no está disponible |

**Ruta rápida:** [GUIA-RELEASE-SCRIPT-AZURE.md](./GUIA-RELEASE-SCRIPT-AZURE.md)  
**Portal visual:** [GUIA-RELEASE-PORTAL-AZURE.md](./GUIA-RELEASE-PORTAL-AZURE.md)

---

## Variables (usar en todos los comandos)

```powershell
$RG = "rg-shopdemo-lab"
$LOCATION = "eastus"
$ACR_NAME = "acrshopdemolab01"
$ACA_ENV = "aca-env-shopdemo"
$LOG_WS = "log-shopdemo"
$EH_NAMESPACE = "shopdemo-eh-ns-lab01"
$EH_NAME = "shopdemo-events"
$STORAGE_NAME = "shopdemochecklab01"
$PG_ACI = "aci-shopdemo-postgres"
$PG_DNS = "shopdemo-pg-lab"
$PG_PASSWORD = "ShopDemo123!"

az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

Tabla completa: [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-AZURE.md) (convención de nombres).

---

## 1. Resource Group

```bash
az group create --name $RG --location $LOCATION
```

---

## 2. Event Hubs

```bash
az eventhubs namespace create --resource-group $RG --name $EH_NAMESPACE --location $LOCATION --sku Basic

az eventhubs eventhub create --resource-group $RG --namespace-name $EH_NAMESPACE --name $EH_NAME --partition-count 2

az eventhubs eventhub consumer-group create --resource-group $RG --namespace-name $EH_NAMESPACE --eventhub-name $EH_NAME --name inventory-service

az eventhubs eventhub consumer-group create --resource-group $RG --namespace-name $EH_NAMESPACE --eventhub-name $EH_NAME --name analytics-service

$EH_CONN = az eventhubs namespace authorization-rule keys list \
  --resource-group $RG --namespace-name $EH_NAMESPACE \
  --name RootManageSharedAccessKey --query primaryConnectionString -o tsv
```

---

## 3. Azure Container Registry

```bash
az acr create --resource-group $RG --name $ACR_NAME --sku Basic --admin-enabled false
az acr login --name $ACR_NAME
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv
```

---

## 4. Log Analytics + Container Apps Environment

```bash
az monitor log-analytics workspace create --resource-group $RG --workspace-name $LOG_WS

$LOG_ID = az monitor log-analytics workspace show --resource-group $RG --workspace-name $LOG_WS --query customerId -o tsv
$LOG_KEY = az monitor log-analytics workspace get-shared-keys --resource-group $RG --workspace-name $LOG_WS --query primarySharedKey -o tsv

az containerapp env create --name $ACA_ENV --resource-group $RG --location $LOCATION \
  --logs-workspace-id $LOG_ID --logs-workspace-key $LOG_KEY
```

---

## 5. PostgreSQL (ACI)

```bash
az container create --resource-group $RG --name $PG_ACI --image postgres:16-alpine \
  --cpu 1 --memory 1.5 --ports 5432 --ip-address Public --dns-name-label $PG_DNS \
  --environment-variables POSTGRES_USER=ShopDemo POSTGRES_PASSWORD=$PG_PASSWORD --location $LOCATION

$PG_FQDN = az container show --resource-group $RG --name $PG_ACI --query ipAddress.fqdn -o tsv
```

Crear bases `ShopDemoCatalog`, `ShopDemoOrders`, `ShopDemoInventory` con `psql` o Cloud Shell.

---

## 6. Storage Account (checkpoints ACA)

```bash
az storage account create --name $STORAGE_NAME --resource-group $RG --location $LOCATION --sku Standard_LRS

$STORAGE_CONN = az storage account show-connection-string --name $STORAGE_NAME --resource-group $RG --query connectionString -o tsv

az storage container create --name inventory-checkpoints --account-name $STORAGE_NAME --auth-mode login
az storage container create --name analytics-checkpoints --account-name $STORAGE_NAME --auth-mode login
```

---

## 7. Container Apps (5 servicios)

Orden: **Catalog** → **Inventory** (interno) → **Orders** → **Analytics** → **MCP**.

Ejemplo Catalog:

```bash
$ACR_PASS = az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv
$PG_CATALOG_CONN = "Host=$PG_FQDN;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=$PG_PASSWORD;Ssl Mode=Require"

az containerapp create --name ca-shopdemo-catalog --resource-group $RG --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-catalog:latest" --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME --registry-password $ACR_PASS \
  --target-port 8080 --ingress external --min-replicas 0 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi \
  --secrets eh-connection="$EH_CONN" pg-catalog-conn="$PG_CATALOG_CONN" \
  --env-vars ASPNETCORE_ENVIRONMENT=Production \
    ConnectionStrings__DefaultConnection=secretref:pg-catalog-conn \
    EventHubs__Enabled=true EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events
```

Comandos completos Inventory/Orders/Analytics/MCP: [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-AZURE.md) §10–§14.

---

## 8. Build y push de imágenes

```bash
cd I:\Curso\ShopDemo

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $ACR_LOGIN/shopdemo-catalog:latest .
docker push $ACR_LOGIN/shopdemo-catalog:latest

docker build -f Orders/ShopDemo.Orders.Api/Dockerfile -t $ACR_LOGIN/shopdemo-orders:latest .
docker push $ACR_LOGIN/shopdemo-orders:latest

docker build -f Inventory/ShopDemo.Inventory.Api/Dockerfile -t $ACR_LOGIN/shopdemo-inventory:latest .
docker push $ACR_LOGIN/shopdemo-inventory:latest

docker build -f Aspire/ShopDemo.Analytics.Api/Dockerfile -t $ACR_LOGIN/shopdemo-analytics:latest .
docker push $ACR_LOGIN/shopdemo-analytics:latest

docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t $ACR_LOGIN/shopdemo-mcp:latest .
docker push $ACR_LOGIN/shopdemo-mcp:latest
```

---

## 9. Limpieza

```bash
az group delete --name $RG --yes --no-wait
```

O `.\Remove-AzureShopDemo.ps1` si usaste el script antes.

---

## Referencia CLI Microsoft

- [az group](https://learn.microsoft.com/cli/azure/group)
- [az acr](https://learn.microsoft.com/cli/azure/acr)
- [az containerapp](https://learn.microsoft.com/cli/azure/containerapp)
- [az eventhubs](https://learn.microsoft.com/cli/azure/eventhubs)
