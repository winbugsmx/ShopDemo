# Guía — Release Azure con Azure CLI (manual)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Enfoque** | **CLI** — comando por comando, sin script |
| **Región lab** | `eastus` |

**Preparación:** [PREPARACION-AMBIENTE-AZURE.md](./PREPARACION-AMBIENTE-AZURE.md)  
**Otras rutas equivalentes:** [Script](./GUIA-RELEASE-SCRIPT-AZURE.md) · [Portal](./GUIA-RELEASE-PORTAL-AZURE.md)

> El resultado final es el **mismo** que con el script o el Portal. Elige **una** ruta según tu preferencia.

---

## Variables de sesión (todas las partes)

```powershell
$SUB = "<TU-SUBSCRIPTION-ID>"
$RG = "rg-shopdemo-lab"
$LOCATION = "eastus"
$ACR_NAME = "acrshopdemolab01"
$ACA_ENV = "aca-env-shopdemo"
$LOG_WS = "log-shopdemo"
$EH_NS = "shopdemo-eh-ns-lab01"
$EH_NAME = "shopdemo-events"
$STORAGE = "shopdemochecklab01"
$PG_ACI = "aci-shopdemo-postgres"
$PG_DNS = "shopdemo-pg-lab"
$PG_USER = "ShopDemo"
$PG_PASS = "ShopDemo123!"
$AKS = "aks-shopdemo"
$TAG = "latest"

az login
az account set --subscription $SUB
az extension add --name containerapp --upgrade -y
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.ContainerService --wait
```

---

# Parte A — Release ACA (Container Apps)

## A.1 Resource Group

```powershell
az group create --name $RG --location $LOCATION
```

## A.2 Event Hubs + consumer groups

```powershell
az eventhubs namespace create -g $RG -n $EH_NS --location $LOCATION --sku Standard

az eventhubs eventhub create -g $RG --namespace-name $EH_NS -n $EH_NAME --partition-count 4

az eventhubs eventhub consumer-group create -g $RG --namespace-name $EH_NS --eventhub-name $EH_NAME --name inventory-service
az eventhubs eventhub consumer-group create -g $RG --namespace-name $EH_NS --eventhub-name $EH_NAME --name analytics-service

$EH_CONN = az eventhubs namespace authorization-rule keys list `
  -g $RG --namespace-name $EH_NS --name RootManageSharedAccessKey `
  --query primaryConnectionString -o tsv
```

## A.3 Storage Account (checkpoints ACA)

```powershell
az storage account create -g $RG -n $STORAGE --location $LOCATION --sku Standard_LRS

$STORAGE_CONN = az storage account show-connection-string -g $RG -n $STORAGE --query connectionString -o tsv

az storage container create --name inventory-checkpoints --account-name $STORAGE --auth-mode login
az storage container create --name analytics-checkpoints --account-name $STORAGE --auth-mode login
```

## A.4 Azure Container Registry

```powershell
az acr create -g $RG -n $ACR_NAME --sku Basic --admin-enabled true
$ACR_LOGIN = az acr show -n $ACR_NAME --query loginServer -o tsv
$ACR_PASS = az acr credential show -n $ACR_NAME --query passwords[0].value -o tsv
az acr login -n $ACR_NAME
```

## A.5 Build y push imágenes (5 servicios)

```powershell
cd I:\Curso\ShopDemo

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t "${ACR_LOGIN}/shopdemo-catalog:${TAG}" .
docker push "${ACR_LOGIN}/shopdemo-catalog:${TAG}"

docker build -f Orders/ShopDemo.Orders.Api/Dockerfile -t "${ACR_LOGIN}/shopdemo-orders:${TAG}" .
docker push "${ACR_LOGIN}/shopdemo-orders:${TAG}"

docker build -f Inventory/ShopDemo.Inventory.Api/Dockerfile -t "${ACR_LOGIN}/shopdemo-inventory:${TAG}" .
docker push "${ACR_LOGIN}/shopdemo-inventory:${TAG}"

docker build -f Aspire/ShopDemo.Analytics.Api/Dockerfile -t "${ACR_LOGIN}/shopdemo-analytics:${TAG}" .
docker push "${ACR_LOGIN}/shopdemo-analytics:${TAG}"

docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t "${ACR_LOGIN}/shopdemo-mcp:${TAG}" .
docker push "${ACR_LOGIN}/shopdemo-mcp:${TAG}"
```

## A.6 Log Analytics + Container Apps Environment

```powershell
az monitor log-analytics workspace create -g $RG -n $LOG_WS

$LOG_ID = az monitor log-analytics workspace show -g $RG -n $LOG_WS --query customerId -o tsv
$LOG_KEY = az monitor log-analytics workspace get-shared-keys -g $RG -n $LOG_WS --query primarySharedKey -o tsv

az containerapp env create -g $RG -n $ACA_ENV --location $LOCATION `
  --logs-workspace-id $LOG_ID --logs-workspace-key $LOG_KEY
```

## A.7 PostgreSQL en ACI

```powershell
az container create -g $RG -n $PG_ACI --image postgres:16-alpine `
  --cpu 1 --memory 1.5 --ports 5432 --ip-address Public --dns-name-label $PG_DNS `
  --location $LOCATION `
  --environment-variables POSTGRES_USER=$PG_USER POSTGRES_PASSWORD=$PG_PASS

$PG_FQDN = az container show -g $RG -n $PG_ACI --query ipAddress.fqdn -o tsv

$env:PGPASSWORD = $PG_PASS
psql -h $PG_FQDN -U $PG_USER -d postgres -c 'CREATE DATABASE "ShopDemoCatalog";'
psql -h $PG_FQDN -U $PG_USER -d postgres -c 'CREATE DATABASE "ShopDemoOrders";'
psql -h $PG_FQDN -U $PG_USER -d postgres -c 'CREATE DATABASE "ShopDemoInventory";'
Remove-Item Env:PGPASSWORD
```

## A.8 Container Apps — Catalog (externo)

```powershell
$PG_CATALOG = "Host=$PG_FQDN;Port=5432;Database=ShopDemoCatalog;Username=$PG_USER;Password=$PG_PASS;Ssl Mode=Require"

az containerapp create -g $RG -n ca-shopdemo-catalog --environment $ACA_ENV `
  --image "${ACR_LOGIN}/shopdemo-catalog:${TAG}" `
  --registry-server $ACR_LOGIN --registry-username $ACR_NAME --registry-password $ACR_PASS `
  --target-port 8080 --ingress external --min-replicas 0 --max-replicas 2 `
  --cpu 0.5 --memory 1.0Gi `
  --secrets eh-connection="$EH_CONN" pg-catalog-conn="$PG_CATALOG" `
  --env-vars ASPNETCORE_ENVIRONMENT=Production `
    ConnectionStrings__DefaultConnection=secretref:pg-catalog-conn `
    EventHubs__Enabled=true EventHubs__ConnectionString=secretref:eh-connection `
    EventHubs__EventHubName=$EH_NAME
```

## A.9 Container Apps — Inventory (interno)

```powershell
$PG_INV = "Host=$PG_FQDN;Port=5432;Database=ShopDemoInventory;Username=$PG_USER;Password=$PG_PASS;Ssl Mode=Require"

az containerapp create -g $RG -n ca-shopdemo-inventory --environment $ACA_ENV `
  --image "${ACR_LOGIN}/shopdemo-inventory:${TAG}" `
  --registry-server $ACR_LOGIN --registry-username $ACR_NAME --registry-password $ACR_PASS `
  --target-port 8080 --ingress internal --min-replicas 1 --max-replicas 2 `
  --cpu 0.5 --memory 1.0Gi `
  --secrets eh-connection="$EH_CONN" pg-inventory-conn="$PG_INV" storage-checkpoint="$STORAGE_CONN" `
  --env-vars ASPNETCORE_ENVIRONMENT=Production `
    ConnectionStrings__DefaultConnection=secretref:pg-inventory-conn `
    EventHubs__Enabled=true EventHubs__ConnectionString=secretref:eh-connection `
    EventHubs__EventHubName=$EH_NAME `
    EventHubs__ConsumerGroup=inventory-service `
    EventHubs__CheckpointStorageConnectionString=secretref:storage-checkpoint `
    EventHubs__CheckpointContainerName=inventory-checkpoints

$INV_FQDN = az containerapp show -g $RG -n ca-shopdemo-inventory --query properties.configuration.ingress.fqdn -o tsv
```

## A.10 Container Apps — Orders (externo)

```powershell
$PG_ORD = "Host=$PG_FQDN;Port=5432;Database=ShopDemoOrders;Username=$PG_USER;Password=$PG_PASS;Ssl Mode=Require"

az containerapp create -g $RG -n ca-shopdemo-orders --environment $ACA_ENV `
  --image "${ACR_LOGIN}/shopdemo-orders:${TAG}" `
  --registry-server $ACR_LOGIN --registry-username $ACR_NAME --registry-password $ACR_PASS `
  --target-port 8080 --ingress external --min-replicas 0 --max-replicas 2 `
  --cpu 0.5 --memory 1.0Gi `
  --secrets eh-connection="$EH_CONN" pg-orders-conn="$PG_ORD" `
  --env-vars ASPNETCORE_ENVIRONMENT=Production `
    ConnectionStrings__DefaultConnection=secretref:pg-orders-conn `
    EventHubs__Enabled=true EventHubs__ConnectionString=secretref:eh-connection `
    EventHubs__EventHubName=$EH_NAME `
    InventoryApi__BaseUrl="https://${INV_FQDN}"
```

## A.11 Container Apps — Analytics (externo)

```powershell
az containerapp create -g $RG -n ca-shopdemo-analytics --environment $ACA_ENV `
  --image "${ACR_LOGIN}/shopdemo-analytics:${TAG}" `
  --registry-server $ACR_LOGIN --registry-username $ACR_NAME --registry-password $ACR_PASS `
  --target-port 8080 --ingress external --min-replicas 1 --max-replicas 1 `
  --cpu 0.5 --memory 1.0Gi `
  --secrets eh-connection="$EH_CONN" storage-checkpoint="$STORAGE_CONN" `
  --env-vars ASPNETCORE_ENVIRONMENT=Production `
    EventHubs__Enabled=true EventHubs__ConnectionString=secretref:eh-connection `
    EventHubs__EventHubName=$EH_NAME `
    EventHubs__ConsumerGroup=analytics-service `
    EventHubs__CheckpointStorageConnectionString=secretref:storage-checkpoint `
    EventHubs__CheckpointContainerName=analytics-checkpoints

$ANALYTICS_FQDN = az containerapp show -g $RG -n ca-shopdemo-analytics --query properties.configuration.ingress.fqdn -o tsv
$CATALOG_FQDN = az containerapp show -g $RG -n ca-shopdemo-catalog --query properties.configuration.ingress.fqdn -o tsv
```

## A.12 Container Apps — MCP (externo)

```powershell
az containerapp create -g $RG -n ca-shopdemo-mcp --environment $ACA_ENV `
  --image "${ACR_LOGIN}/shopdemo-mcp:${TAG}" `
  --registry-server $ACR_LOGIN --registry-username $ACR_NAME --registry-password $ACR_PASS `
  --target-port 8080 --ingress external --min-replicas 1 --max-replicas 2 `
  --cpu 0.5 --memory 1.0Gi `
  --env-vars ASPNETCORE_ENVIRONMENT=Production `
    ShopDemo__CatalogApiBaseUrl="https://${CATALOG_FQDN}" `
    ShopDemo__InventoryApiBaseUrl="https://${INV_FQDN}" `
    ShopDemo__AnalyticsApiBaseUrl="https://${ANALYTICS_FQDN}"
```

## A.13 Validación ACA

```powershell
az containerapp list -g $RG --query "[].{name:name,url:properties.configuration.ingress.fqdn}" -o table
# https://<fqdn-catalog>/swagger/index.html
# https://<fqdn-mcp>/health
```

## A.14 Teardown ACA

```powershell
az group delete --name $RG --yes --no-wait
```

---

# Parte B — Release AKS (lab validado)

## B.1 Resource Group (si no existe)

```powershell
az group create --name $RG --location $LOCATION
```

## B.2 Event Hubs + consumer groups

Repetir **A.2** si no tienes Event Hubs del release ACA.

## B.3 ACR (si no existe)

Repetir **A.4** y **A.5** si no hay imágenes en ACR.

## B.4 Crear cluster AKS

```powershell
az aks create -g $RG -n $AKS --location $LOCATION `
  --node-count 2 --node-vm-size Standard_B2s `
  --attach-acr $ACR_NAME `
  --generate-ssh-keys

az aks get-credentials -g $RG -n $AKS --overwrite-existing
kubectl get nodes
```

## B.5 Ingress NGINX (Helm + health probe Azure)

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  -n ingress-nginx --create-namespace `
  --set controller.admissionWebhooks.enabled=false `
  --set controller.service.externalTrafficPolicy=Local `
  --set-string controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
  --set controller.resources.requests.cpu=100m `
  --set controller.resources.requests.memory=128Mi `
  --wait --timeout 5m

kubectl get svc ingress-nginx-controller -n ingress-nginx
```

## B.6 Secrets Kubernetes

```powershell
cd I:\Curso\ShopDemo
copy k8s\secrets.example.yaml k8s\secrets.yaml
notepad k8s\secrets.yaml   # Pegar EVENT_HUBS_CONNECTION_STRING ($EH_CONN)
kubectl apply -f k8s\namespace.yaml
kubectl apply -f k8s\secrets.yaml
```

## B.7 Aplicar manifiestos (orden) — AKS

Deployments en **`k8s/azure/`** (ACR). Services compartidos en `k8s/*/service.yaml`.

```powershell
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/deployment.yaml
kubectl apply -f k8s/azurite/service.yaml
kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/inventory/service.yaml
kubectl apply -f k8s/analytics/service.yaml
kubectl apply -f k8s/mcp/service.yaml
kubectl apply -f k8s/azure/catalog/deployment.yaml
kubectl apply -f k8s/azure/orders/deployment.yaml
kubectl apply -f k8s/azure/inventory/deployment.yaml
kubectl apply -f k8s/azure/analytics/deployment.yaml
kubectl apply -f k8s/azure/mcp/deployment.yaml
kubectl apply -f k8s/ingress/

# Solo si el tag del push difiere del YAML:
kubectl set image deployment/shopdemo-catalog catalog-api="${ACR_LOGIN}/shopdemo-catalog:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-orders orders-api="${ACR_LOGIN}/shopdemo-orders:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-inventory inventory-api="${ACR_LOGIN}/shopdemo-inventory:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-analytics analytics-api="${ACR_LOGIN}/shopdemo-analytics:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-mcp mcp-api="${ACR_LOGIN}/shopdemo-mcp:${TAG}" -n shopdemo

kubectl delete hpa shopdemo-catalog-hpa -n shopdemo --ignore-not-found
kubectl apply -f k8s/azurite/init-checkpoints-job.yaml
kubectl wait --for=condition=complete job/shopdemo-azurite-init -n shopdemo --timeout=120s
```

## B.8 Analytics — entorno y Event Hubs

```powershell
kubectl set env deployment/shopdemo-analytics -n shopdemo ASPNETCORE_ENVIRONMENT=Development EventHubs__Enabled=true
kubectl rollout restart deployment/shopdemo-analytics -n shopdemo
kubectl rollout status deployment/shopdemo-analytics -n shopdemo --timeout=180s
```

## B.9 Archivo hosts + validación Ingress

```powershell
$ING_IP = kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "Agregar en hosts: $ING_IP shopdemo.local"
```

Probar:

```powershell
$H = @{ Host = "shopdemo.local" }
Invoke-WebRequest -Uri "http://${ING_IP}/catalog/swagger/index.html" -Headers $H -UseBasicParsing
Invoke-WebRequest -Uri "http://${ING_IP}/mcp/health" -Headers $H -UseBasicParsing
```

## B.10 Validación LoadBalancer directo (:8080)

```powershell
kubectl get svc -n shopdemo
curl.exe "http://<IP-catalog>:8080/swagger/index.html"
```

## B.11 Teardown AKS

```powershell
az group delete --name $RG --yes --no-wait
```

---

## Referencias

| Documento | Contenido |
|---|---|
| [PREPARACION-AMBIENTE-AZURE.md](./PREPARACION-AMBIENTE-AZURE.md) | IAM, cuotas, herramientas |
| [GUIA-RELEASE-SCRIPT-AZURE.md](./GUIA-RELEASE-SCRIPT-AZURE.md) | Script PowerShell |
| [GUIA-RELEASE-PORTAL-AZURE.md](./GUIA-RELEASE-PORTAL-AZURE.md) | Consola web |
