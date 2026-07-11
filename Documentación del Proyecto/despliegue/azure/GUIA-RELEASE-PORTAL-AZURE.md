# Guía — Release Azure desde el Portal (Consola web)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Enfoque** | **Portal** — consola web paso a paso |
| **Región lab** | `East US` (`eastus`) |

**Preparación:** [PREPARACION-AMBIENTE-AZURE.md](./PREPARACION-AMBIENTE-AZURE.md)  
**Otras rutas equivalentes:** [Script](./GUIA-RELEASE-SCRIPT-AZURE.md) · [CLI](./GUIA-RELEASE-CLI-AZURE.md)

> El resultado final es el **mismo** que con el script o la CLI. Para AKS, algunos pasos finales usan `kubectl` en tu PC (incluidos abajo).

---

## Nombres canónicos (usar en todo el lab)

| Recurso | Nombre Portal |
|---|---|
| Resource group | `rg-shopdemo-lab` |
| Event Hubs namespace | `shopdemo-eh-ns-lab01` |
| Event hub | `shopdemo-events` |
| Container registry | `acrshopdemolab01` |
| Storage account | `shopdemochecklab01` |
| Log Analytics | `log-shopdemo` |
| ACA environment | `aca-env-shopdemo` |
| PostgreSQL ACI | `aci-shopdemo-postgres` |
| AKS cluster | `aks-shopdemo` |

---

# Parte A — Release ACA (Container Apps)

## A.0 Acceso al Portal

1. [https://portal.azure.com](https://portal.azure.com)
2. Confirmar suscripción correcta (barra superior)
3. Anotar **Subscription ID** para `.env.azure` / CLI

---

## A.1 Resource Group

1. Buscar **Resource groups** → **Create**
2. **Name:** `rg-shopdemo-lab`
3. **Region:** `East US`
4. **Review + create** → **Create**

---

## A.2 Event Hubs

1. **Create a resource** → **Event Hubs**
2. **Namespace name:** `shopdemo-eh-ns-lab01`
3. **Resource group:** `rg-shopdemo-lab`
4. **Pricing tier:** Standard → **Create**
5. Namespace → **Event Hubs** → **+ Event Hub**
   - **Name:** `shopdemo-events`
   - **Partition count:** 4
6. Event hub → **Consumer groups** → **+ Consumer group:**
   - `inventory-service`
   - `analytics-service`
7. Namespace → **Shared access policies** → **RootManageSharedAccessKey** → copiar **Primary Connection String**

---

## A.3 Storage Account

1. **Create a resource** → **Storage account**
2. **Name:** `shopdemochecklab01`
3. **Resource group:** `rg-shopdemo-lab`
4. **Performance:** Standard · **Redundancy:** LRS → **Create**
5. Storage → **Containers** → **+ Container:**
   - `inventory-checkpoints`
   - `analytics-checkpoints`

---

## A.4 Azure Container Registry

1. **Create a resource** → **Container Registry**
2. **Registry name:** `acrshopdemolab01`
3. **SKU:** Basic
4. **Admin user:** Enabled (lab) → **Create**
5. Anotar **Login server:** `acrshopdemolab01.azurecr.io`

---

## A.5 Build y push imágenes (PC local)

En PowerShell (raíz del repo):

```powershell
az acr login --name acrshopdemolab01
$LOGIN = "acrshopdemolab01.azurecr.io"
cd I:\Curso\ShopDemo

docker build -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile -t "$LOGIN/shopdemo-catalog:latest" .
docker push "$LOGIN/shopdemo-catalog:latest"
docker build -f Source/Orders/ShopDemo.Orders.Api/Dockerfile -t "$LOGIN/shopdemo-orders:latest" .
docker push "$LOGIN/shopdemo-orders:latest"
docker build -f Source/Inventory/ShopDemo.Inventory.Api/Dockerfile -t "$LOGIN/shopdemo-inventory:latest" .
docker push "$LOGIN/shopdemo-inventory:latest"
docker build -f Source/Aspire/ShopDemo.Analytics.Api/Dockerfile -t "$LOGIN/shopdemo-analytics:latest" .
docker push "$LOGIN/shopdemo-analytics:latest"
docker build -f Source/AI/ShopDemo.Mcp.Api/Dockerfile -t "$LOGIN/shopdemo-mcp:latest" .
docker push "$LOGIN/shopdemo-mcp:latest"
```

Verificar en Portal: ACR → **Repositories** → 5 imágenes `shopdemo-*`.

---

## A.6 Log Analytics + Container Apps Environment

1. **Create a resource** → **Container Apps Environment**
2. **Environment name:** `aca-env-shopdemo`
3. **Region:** East US
4. **Logs:** Create new → **Name:** `log-shopdemo`
5. **Create**

---

## A.7 PostgreSQL en Container Instances

1. **Create a resource** → **Container Instances**
2. **Name:** `aci-shopdemo-postgres`
3. **Image:** `postgres:16-alpine`
4. **Size:** 1 vCPU, 1.5 GiB
5. **Networking:** Public · **DNS name label:** `shopdemo-pg-lab` · Port **5432**
6. **Environment variables:**
   - `POSTGRES_USER` = `ShopDemo`
   - `POSTGRES_PASSWORD` = `ShopDemo123!`
7. **Create** → anotar **FQDN** en Overview

Crear bases de datos (Cloud Shell o `psql` local):

```sql
CREATE DATABASE "ShopDemoCatalog";
CREATE DATABASE "ShopDemoOrders";
CREATE DATABASE "ShopDemoInventory";
```

---

## A.8 Container App — Catalog

1. **Container Apps** → **Create**
2. **Basics:** Name `ca-shopdemo-catalog`, Environment `aca-env-shopdemo`
3. **Container:**
   - Image: `acrshopdemolab01.azurecr.io/shopdemo-catalog:latest`
   - CPU 0.5, Memory 1 Gi · Target port **8080**
   - Registry: ACR admin credentials
4. **Ingress:** Enabled · **External** · Target port 8080
5. **Secrets:** `eh-connection` (Event Hubs string), `pg-catalog-conn` (connection string PostgreSQL catalog)
6. **Environment variables:**

| Name | Value |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ConnectionStrings__DefaultConnection` | secret `pg-catalog-conn` |
| `EventHubs__Enabled` | `true` |
| `EventHubs__ConnectionString` | secret `eh-connection` |
| `EventHubs__EventHubName` | `shopdemo-events` |

7. **Create** → anotar **Application Url** (FQDN Catalog)

---

## A.9 Container App — Inventory (interno)

Igual que Catalog con:

| Campo | Valor |
|---|---|
| Name | `ca-shopdemo-inventory` |
| Image | `shopdemo-inventory:latest` |
| Ingress | **Internal** (vNet) |
| Secrets | `eh-connection`, `pg-inventory-conn`, `storage-checkpoint` (Storage connection string) |
| Env extra | `EventHubs__ConsumerGroup=inventory-service`, `EventHubs__CheckpointStorageConnectionString`, `EventHubs__CheckpointContainerName=inventory-checkpoints` |

Anotar **FQDN interno** de Inventory.

---

## A.10 Container App — Orders

| Campo | Valor |
|---|---|
| Name | `ca-shopdemo-orders` |
| Ingress | **External** |
| Secret | `pg-orders-conn` |
| Env extra | `InventoryApi__BaseUrl` = `https://<fqdn-inventory>` |

---

## A.11 Container App — Analytics

| Campo | Valor |
|---|---|
| Name | `ca-shopdemo-analytics` |
| Ingress | **External** |
| Min replicas | 1 |
| Secrets | `eh-connection`, `storage-checkpoint` |
| Env extra | `EventHubs__ConsumerGroup=analytics-service`, `EventHubs__CheckpointContainerName=analytics-checkpoints` |

Anotar FQDN Analytics.

---

## A.12 Container App — MCP

| Campo | Valor |
|---|---|
| Name | `ca-shopdemo-mcp` |
| Ingress | **External** |
| Env | `ShopDemo__CatalogApiBaseUrl=https://<fqdn-catalog>` |
| Env | `ShopDemo__InventoryApiBaseUrl=https://<fqdn-inventory>` |
| Env | `ShopDemo__AnalyticsApiBaseUrl=https://<fqdn-analytics>` |

---

## A.13 Validación ACA

| App | URL |
|---|---|
| Catalog | `https://<fqdn>/swagger/index.html` |
| Orders | `https://<fqdn>/swagger/index.html` |
| Analytics | `https://<fqdn>/swagger/index.html` |
| MCP | `https://<fqdn>/health` |

Portal: cada Container App → **Application Url** → navegador.

---

# Parte B — Release AKS (Portal + kubectl)

## B.1 Prerrequisitos en PC

- `az`, `kubectl`, `helm`, Docker
- Imágenes en ACR (Parte A §A.5)
- Event Hubs + consumer groups (Parte A §A.2)

---

## B.2 Crear cluster AKS en Portal

1. **Create a resource** → **Kubernetes Service**
2. **Basics:**
   - **Cluster name:** `aks-shopdemo`
   - **Resource group:** `rg-shopdemo-lab`
   - **Region:** East US
3. **Node pools:**
   - **Node size:** `Standard_B2s`
   - **Node count:** **2**
4. **Integrations:**
   - **Container registry:** `acrshopdemolab01` (Attach)
5. **Networking:** defaults (lab)
6. **Review + create** → esperar **Succeeded** (~10–15 min)

---

## B.3 Conectar kubectl

```powershell
az aks get-credentials -g rg-shopdemo-lab -n aks-shopdemo --overwrite-existing
kubectl get nodes
```

Portal: cluster → **Connect** → copiar comando.

---

## B.4 Ingress NGINX (Helm en PC)

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
```

Portal: **Kubernetes services** → namespace `ingress-nginx` → ver LoadBalancer IP.

---

## B.5 Secrets y manifiestos Kubernetes

```powershell
cd I:\Curso\ShopDemo
copy k8s\secrets.example.yaml k8s\secrets.yaml
notepad k8s\secrets.yaml   # EVENT_HUBS_CONNECTION_STRING de Parte A §A.2

kubectl apply -f k8s\namespace.yaml
kubectl apply -f k8s\secrets.yaml
kubectl apply -f k8s\postgres\
kubectl apply -f k8s\azurite\deployment.yaml
kubectl apply -f k8s\azurite\service.yaml
kubectl apply -f k8s\catalog\service.yaml
kubectl apply -f k8s\orders\service.yaml
kubectl apply -f k8s\inventory\service.yaml
kubectl apply -f k8s\analytics\service.yaml
kubectl apply -f k8s\mcp\service.yaml
kubectl apply -f k8s\azure\catalog\deployment.yaml
kubectl apply -f k8s\azure\orders\deployment.yaml
kubectl apply -f k8s\azure\inventory\deployment.yaml
kubectl apply -f k8s\azure\analytics\deployment.yaml
kubectl apply -f k8s\azure\mcp\deployment.yaml
kubectl apply -f k8s\ingress\

$ACR = "acrshopdemolab01.azurecr.io"
# Solo si el tag del push difiere del YAML (latest vs v1):
kubectl set image deployment/shopdemo-catalog catalog-api="${ACR}/shopdemo-catalog:latest" -n shopdemo
kubectl set image deployment/shopdemo-orders orders-api="${ACR}/shopdemo-orders:latest" -n shopdemo
kubectl set image deployment/shopdemo-inventory inventory-api="${ACR}/shopdemo-inventory:latest" -n shopdemo
kubectl set image deployment/shopdemo-analytics analytics-api="${ACR}/shopdemo-analytics:latest" -n shopdemo
kubectl set image deployment/shopdemo-mcp mcp-api="${ACR}/shopdemo-mcp:latest" -n shopdemo

kubectl delete hpa shopdemo-catalog-hpa -n shopdemo --ignore-not-found
kubectl apply -f k8s\azurite\init-checkpoints-job.yaml
kubectl wait --for=condition=complete job/shopdemo-azurite-init -n shopdemo --timeout=120s

kubectl set env deployment/shopdemo-analytics -n shopdemo ASPNETCORE_ENVIRONMENT=Development EventHubs__Enabled=true
kubectl rollout restart deployment/shopdemo-analytics -n shopdemo
```

---

## B.6 Archivo hosts

1. Obtener IP Ingress:

```powershell
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

2. Editar `C:\Windows\System32\drivers\etc\hosts` (admin):

```
<IP-INGRESS> shopdemo.local
```

---

## B.7 Validación AKS

**Ingress (puerto 80):**

| URL |
|---|
| http://shopdemo.local/catalog/swagger/index.html |
| http://shopdemo.local/orders/swagger/index.html |
| http://shopdemo.local/inventory/swagger/index.html |
| http://shopdemo.local/analytics/swagger/index.html |
| http://shopdemo.local/mcp/health |

**LoadBalancer directo:**

Portal → **Kubernetes resources** → **Services** → namespace `shopdemo` → IPs externas puerto **8080**.

---

## B.8 Monitoreo en Portal

| Qué | Dónde |
|---|---|
| Cluster estado | **Kubernetes services** → `aks-shopdemo` |
| Nodos | **Node pools** |
| Load Balancers | **Load balancing** (IP Ingress y servicios) |
| Logs AKS | **Monitor** → **Logs** |

---

## B.9 Limpieza

**Resource groups** → `rg-shopdemo-lab` → **Delete resource group** → confirmar nombre.

---

## Referencias

| Documento | Uso |
|---|---|
| [PREPARACION-AMBIENTE-AZURE.md](./PREPARACION-AMBIENTE-AZURE.md) | IAM, cuotas |
| [GUIA-RELEASE-CLI-AZURE.md](./GUIA-RELEASE-CLI-AZURE.md) | Comandos exactos |
| [GUIA-RELEASE-SCRIPT-AZURE.md](./GUIA-RELEASE-SCRIPT-AZURE.md) | Script PowerShell |
| [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md) | Event Hubs |
