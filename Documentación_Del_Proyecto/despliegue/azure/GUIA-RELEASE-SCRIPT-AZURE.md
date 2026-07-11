# Guía — Release Azure con script PowerShell

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Enfoque** | **Script** — `Deploy-AzureShopDemo.ps1` |
| **Modos** | `ACA` · `AKS` · `All` |

**Preparación:** [PREPARACION-AMBIENTE-AZURE.md](./PREPARACION-AMBIENTE-AZURE.md)  
**Otras rutas equivalentes:** [CLI](./GUIA-RELEASE-CLI-AZURE.md) · [Portal](./GUIA-RELEASE-PORTAL-AZURE.md)

> El resultado final es el **mismo** que con CLI o Portal. El script **no hace build Docker**; los pasos de build están incluidos abajo.

---

## 1. Resumen de las tres rutas

| Ruta | Documento | Tiempo aprox. |
|---|---|---|
| **Script** (esta guía) | `Deploy-AzureShopDemo.ps1` | 2–4 h |
| **CLI** | [GUIA-RELEASE-CLI-AZURE.md](./GUIA-RELEASE-CLI-AZURE.md) | 6–10 h |
| **Portal** | [GUIA-RELEASE-PORTAL-AZURE.md](./GUIA-RELEASE-PORTAL-AZURE.md) | 8–12 h |

| Modo | Qué crea el script | Qué **tú** haces |
|---|---|---|
| **ACA** | RG, Event Hubs, Storage, ACR, Log Analytics, ACA Env, PostgreSQL ACI, 5 Container Apps + MCP | `.env.azure`, build/push ACR, consumer groups EH |
| **AKS** | RG, Event Hubs, ACR, cluster AKS, `k8s/secrets.yaml`, Ingress Helm (puede fallar §7) | build/push ACR, `kubectl apply`, consumer groups, health probe Ingress |
| **All** | ACA + AKS | Todo lo anterior |

---

## 2. Paso 0 — Preparación

### 2.1 Herramientas

Ver [PREPARACION-AMBIENTE-AZURE.md §1](./PREPARACION-AMBIENTE-AZURE.md#1-herramientas-en-tu-pc).

### 2.2 Configurar `.env.azure`

```powershell
cd I:\Curso\ShopDemo\Source\scripts\azure
copy .env.azure.example .env.azure
notepad .env.azure
```

| Variable | Valor lab |
|---|---|
| `AZURE_SUBSCRIPTION_ID` | GUID de tu suscripción |
| `AZURE_LOCATION` | `eastus` |
| `RESOURCE_GROUP` | `rg-shopdemo-lab` |
| `ACR_NAME` | `acrshopdemolab01` |
| `EVENT_HUB_NAMESPACE` | `shopdemo-eh-ns-lab01` |
| `EVENT_HUB_NAME` | `shopdemo-events` |
| `STORAGE_ACCOUNT_NAME` | `shopdemochecklab01` |
| `POSTGRES_PASSWORD` | `ShopDemo123!` |
| `AKS_CLUSTER_NAME` | `aks-shopdemo` |
| `AKS_NODE_COUNT` | **`2`** |
| `AKS_NODE_VM_SIZE` | `Standard_B2s` |
| `IMAGE_TAG` | `latest` |

### 2.3 Login Azure

```powershell
az login
az account set --subscription "<TU-SUBSCRIPTION-ID>"
az account show --query name -o tsv
```

---

## 3. Paso 1 — Build y push imágenes ACR (obligatorio)

El script crea ACR pero **no construye imágenes**. Ejecuta **antes** o **después** del script (las apps/pods fallan sin imágenes):

```powershell
$ACR_NAME = "acrshopdemolab01"
$TAG = "latest"
az acr login --name $ACR_NAME
$LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv

cd I:\Curso\ShopDemo

docker build -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile -t "${LOGIN}/shopdemo-catalog:${TAG}" .
docker push "${LOGIN}/shopdemo-catalog:${TAG}"

docker build -f Source/Orders/ShopDemo.Orders.Api/Dockerfile -t "${LOGIN}/shopdemo-orders:${TAG}" .
docker push "${LOGIN}/shopdemo-orders:${TAG}"

docker build -f Source/Inventory/ShopDemo.Inventory.Api/Dockerfile -t "${LOGIN}/shopdemo-inventory:${TAG}" .
docker push "${LOGIN}/shopdemo-inventory:${TAG}"

docker build -f Source/Aspire/ShopDemo.Analytics.Api/Dockerfile -t "${LOGIN}/shopdemo-analytics:${TAG}" .
docker push "${LOGIN}/shopdemo-analytics:${TAG}"

docker build -f Source/AI/ShopDemo.Mcp.Api/Dockerfile -t "${LOGIN}/shopdemo-mcp:${TAG}" .
docker push "${LOGIN}/shopdemo-mcp:${TAG}"

az acr repository list --name $ACR_NAME -o table
```

---

## 4. Modo ACA — paso a paso

### 4.1 Consumer groups Event Hubs (antes o después del script)

```powershell
$RG = "rg-shopdemo-lab"
az eventhubs eventhub consumer-group create -g $RG --namespace-name shopdemo-eh-ns-lab01 --eventhub-name shopdemo-events --name inventory-service
az eventhubs eventhub consumer-group create -g $RG --namespace-name shopdemo-eh-ns-lab01 --eventhub-name shopdemo-events --name analytics-service
```

### 4.2 Ejecutar script

```powershell
cd I:\Curso\ShopDemo\Source\scripts\azure
.\Deploy-AzureShopDemo.ps1 -Mode ACA
```

**Duración:** ~20–40 min.

### 4.3 Qué hace el script (orden interno)

| Paso | Recursos |
|---|---|
| 0 | Azure CLI, extensiones, proveedores |
| 1 | Resource Group |
| 2 | Event Hubs namespace + hub, Storage Account + contenedores blob |
| 3 | ACR |
| 4 | PostgreSQL ACI + creación de 3 bases de datos |
| 5 | Log Analytics + Container Apps Environment |
| 6 | Container Apps: catalog, inventory (internal), orders, analytics, mcp |

### 4.4 Validación ACA

El script imprime FQDN de cada Container App:

```powershell
az containerapp list -g rg-shopdemo-lab --query "[].{name:name,fqdn:properties.configuration.ingress.fqdn}" -o table
```

| App | URL patrón |
|---|---|
| Catalog | `https://<fqdn-catalog>/swagger/index.html` |
| Orders | `https://<fqdn-orders>/swagger/index.html` |
| Analytics | `https://<fqdn-analytics>/swagger/index.html` |
| MCP | `https://<fqdn-mcp>/health` |

### 4.5 Teardown ACA

```powershell
.\Remove-AzureShopDemo.ps1
```

---

## 5. Modo AKS — paso a paso (lab validado)

### 5.1 Ejecutar script

```powershell
cd I:\Curso\ShopDemo\Source\scripts\azure
.\Deploy-AzureShopDemo.ps1 -Mode AKS
```

**Duración:** ~15–25 min (cluster AKS).

**Qué hace el script:**

| Paso | Acción |
|---|---|
| 1–3 | RG, Event Hubs, ACR |
| 7 | `az aks create` + `--attach-acr` |
| 7 | `az aks get-credentials` |
| 7 | Helm Ingress NGINX (puede fallar — ver §5.3) |
| 7 | Genera `k8s/secrets.yaml` |

> PostgreSQL en AKS usa **`k8s/postgres/`** in-cluster, no ACI.

### 5.2 Pasos manuales post-script (obligatorios)

#### 5.2.1 Consumer groups Event Hubs

```powershell
az eventhubs eventhub consumer-group create -g rg-shopdemo-lab --namespace-name shopdemo-eh-ns-lab01 --eventhub-name shopdemo-events --name analytics-service
az eventhubs eventhub consumer-group create -g rg-shopdemo-lab --namespace-name shopdemo-eh-ns-lab01 --eventhub-name shopdemo-events --name inventory-service
```

#### 5.2.2 Ingress NGINX (si el script falló en Helm/kubectl)

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

> **Crítico en Azure:** sin la anotación `health-probe-request-path=/healthz`, el Load Balancer **no enruta tráfico** al Ingress.

#### 5.2.3 Aplicar manifiestos Kubernetes

Los **Deployments** de AKS están en `k8s/azure/` (imágenes ACR). Los **Services** son compartidos en `k8s/*/service.yaml`.

```powershell
$ACR = "acrshopdemolab01.azurecr.io"
$TAG = "latest"
cd I:\Curso\ShopDemo

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/deployment.yaml
kubectl apply -f k8s/azurite/service.yaml

# Services compartidos
kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/inventory/service.yaml
kubectl apply -f k8s/analytics/service.yaml
kubectl apply -f k8s/mcp/service.yaml

# Deployments AKS (ACR — ya referencian $ACR en YAML)
kubectl apply -f k8s/azure/catalog/deployment.yaml
kubectl apply -f k8s/azure/orders/deployment.yaml
kubectl apply -f k8s/azure/inventory/deployment.yaml
kubectl apply -f k8s/azure/analytics/deployment.yaml
kubectl apply -f k8s/azure/mcp/deployment.yaml

kubectl apply -f k8s/ingress/

# Solo si el tag del push difiere del YAML (ej. v1 vs latest):
kubectl set image deployment/shopdemo-catalog catalog-api="${ACR}/shopdemo-catalog:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-orders orders-api="${ACR}/shopdemo-orders:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-inventory inventory-api="${ACR}/shopdemo-inventory:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-analytics analytics-api="${ACR}/shopdemo-analytics:${TAG}" -n shopdemo
kubectl set image deployment/shopdemo-mcp mcp-api="${ACR}/shopdemo-mcp:${TAG}" -n shopdemo

kubectl delete hpa shopdemo-catalog-hpa -n shopdemo --ignore-not-found
kubectl apply -f k8s/azurite/init-checkpoints-job.yaml
kubectl wait --for=condition=complete job/shopdemo-azurite-init -n shopdemo --timeout=120s
```

**Alternativa:** `APPLY_INFRA=true bash .github/scripts/apply-k8s-manifests.sh k8s azure` (Git Bash) + `kubectl apply -f k8s/secrets.yaml` + ingress.

#### 5.2.4 Analytics — variables de entorno

```powershell
kubectl set env deployment/shopdemo-analytics -n shopdemo `
  ASPNETCORE_ENVIRONMENT=Development `
  EventHubs__Enabled=true
kubectl rollout restart deployment/shopdemo-analytics -n shopdemo
kubectl rollout status deployment/shopdemo-analytics -n shopdemo --timeout=180s
```

### 5.3 Archivo hosts (Ingress)

Obtener IP del Ingress:

```powershell
kubectl get svc ingress-nginx-controller -n ingress-nginx
kubectl get ingress shopdemo-ingress -n shopdemo
```

Agregar en `C:\Windows\System32\drivers\etc\hosts` (como administrador):

```
<IP-INGRESS> shopdemo.local
```

Ejemplo lab validado: `20.42.38.69 shopdemo.local`

### 5.4 Validación AKS

**Vía Ingress (puerto 80):**

| Servicio | URL |
|---|---|
| Catalog Swagger | http://shopdemo.local/catalog/swagger/index.html |
| Orders Swagger | http://shopdemo.local/orders/swagger/index.html |
| Inventory Swagger | http://shopdemo.local/inventory/swagger/index.html |
| Analytics Swagger | http://shopdemo.local/analytics/swagger/index.html |
| MCP health | http://shopdemo.local/mcp/health |

**Vía LoadBalancer directo (puerto 8080):**

```powershell
kubectl get svc -n shopdemo shopdemo-catalog shopdemo-orders shopdemo-inventory shopdemo-mcp
```

| API | URL patrón |
|---|---|
| Catalog | `http://<EXTERNAL-IP>:8080/swagger/index.html` |
| Orders | `http://<EXTERNAL-IP>:8080/swagger/index.html` |
| Inventory | `http://<EXTERNAL-IP>:8080/swagger/index.html` |
| MCP | `http://<EXTERNAL-IP>:8080/health` |

Referencia: [`Source/scripts/azure/deploy-aks-report.json`](../../../Source/scripts/azure/deploy-aks-report.json)

### 5.5 Teardown AKS

```powershell
.\Remove-AzureShopDemo.ps1
# O: az group delete -n rg-shopdemo-lab --yes
```

---

## 6. Modo All (ACA + AKS)

```powershell
.\Deploy-AzureShopDemo.ps1 -Mode All
```

Orden: build/push ACR → script → consumer groups → pasos AKS §5.2 → validar ACA §4.4 y AKS §5.4.

---

## 7. Ajustes conocidos del script (changelog)

| Ajuste | Motivo |
|---|---|
| `$ErrorActionPreference = 'Stop'` + `kubectl get namespace` | Falla si namespace `ingress-nginx` no existe (stderr) — instalar Helm manualmente §5.2.2 |
| AKS intenta regiones alternativas | `eastus`, `eastus2`, `centralus` si cuota falla |
| `--attach-acr` en `aks create` | Pull de imágenes sin secret manual |
| No crea consumer groups EH | Crear manualmente §4.1 / §5.2.1 |
| Genera `k8s/secrets.yaml` | Event Hubs + Postgres in-cluster |

---

## 8. Solución de problemas

| Síntoma | Acción |
|---|---|
| `Image pull failed` | Completar §3 (push ACR) |
| Analytics CrashLoopBackOff | Crear consumer group `analytics-service` |
| Ingress timeout externo | Anotación `health-probe-request-path=/healthz` §5.2.2 |
| Swagger 404 en AKS | `ASPNETCORE_ENVIRONMENT=Development` en deployment |
| Ingress 404 | Verificar entrada `hosts` con `shopdemo.local` |
| Script falla en Ingress | Continuar con §5.2.2 manual |
| Nombre ACR/EH ocupado | Sufijo `02` en `.env.azure` |

---

## 9. Referencias

| Tema | Enlace |
|---|---|
| Preparación | [PREPARACION-AMBIENTE-AZURE.md](./PREPARACION-AMBIENTE-AZURE.md) |
| CLI paso a paso | [GUIA-RELEASE-CLI-AZURE.md](./GUIA-RELEASE-CLI-AZURE.md) |
| Portal | [GUIA-RELEASE-PORTAL-AZURE.md](./GUIA-RELEASE-PORTAL-AZURE.md) |
| Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md) |
| Endpoints Postman | [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) |
