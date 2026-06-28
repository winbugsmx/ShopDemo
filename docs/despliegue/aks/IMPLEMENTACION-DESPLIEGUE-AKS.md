# Implementación — Despliegue en Azure AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisito:** [IMPLEMENTACION-KUBERNETES-LOCAL.md](../kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) (Minikube)  
**Preparación:** [PREPARACION-AMBIENTE-AZURE.md](../azure/PREPARACION-AMBIENTE-AZURE.md)  
**Guías actualizadas (recomendadas):** [GUIA-RELEASE-SCRIPT-AZURE.md](../azure/GUIA-RELEASE-SCRIPT-AZURE.md) · [GUIA-RELEASE-CLI-AZURE.md](../azure/GUIA-RELEASE-CLI-AZURE.md) · [GUIA-RELEASE-PORTAL-AZURE.md](../azure/GUIA-RELEASE-PORTAL-AZURE.md)  
**Release AKS validado:** Ingress `shopdemo.local`, health probe `/healthz`, consumer groups EH — ver guía Script §5  
**Script:** [scripts/azure/README.md](../../../scripts/azure/README.md) · **Reporte:** [deploy-aks-report.json](../../../scripts/azure/deploy-aks-report.json)

---

## Índice

0. [Script PowerShell (`-Mode AKS`)](#0-script-powershell--mode-aks)
1. [Variables del laboratorio](#1-variables-del-laboratorio)
2. [Paso 1 — Resource Group y ACR](#2-paso-1--resource-group-y-acr)
3. [Paso 2 — Crear cluster AKS](#3-paso-2--crear-cluster-aks)
4. [Paso 3 — Conectar kubectl](#4-paso-3--conectar-kubectl)
5. [Paso 4 — Build y push a ACR](#5-paso-4--build-y-push-a-acr)
6. [Paso 5 — Instalar Ingress NGINX](#6-paso-5--instalar-ingress-nginx)
7. [Paso 6 — Ajustar manifiestos para ACR](#7-paso-6--ajustar-manifiestos-para-acr)
8. [Paso 7 — Desplegar ShopDemo](#8-paso-7--desplegar-shopdemo)
9. [Paso 8 — Secrets, Probes y HPA](#9-paso-8--secrets-probes-y-hpa)
10. [Paso 9 — Testeo](#10-paso-9--testeo)
11. [Paso 10 — Limpieza](#11-paso-10--limpieza)

---

## 0. Script PowerShell (`-Mode AKS`)

Puedes crear el cluster AKS, Ingress NGINX y el archivo `k8s/secrets.yaml` con el **mismo script** usado para Container Apps:

```powershell
cd I:\Curso\ShopDemo\scripts\azure
copy .env.azure.example .env.azure   # si aún no existe
notepad .env.azure                    # AKS_CLUSTER_NAME, ACR_NAME, etc.

az login
.\Deploy-AzureShopDemo.ps1 -Mode AKS
```

| Qué hace el script | Qué debes hacer tú después |
|---|---|
| Resource Group, Event Hubs, Storage, ACR | `docker push` 5 imágenes a ACR |
| Cluster AKS + `az aks get-credentials` | Editar `k8s/*/deployment.yaml` → imagen ACR |
| Helm Ingress NGINX | `kubectl apply -f k8s/` (orden en [k8s/README.md](../../../k8s/README.md)) |
| Genera `k8s/secrets.yaml` | **No commitear** secrets |

Guía completa del script: [scripts/azure/README.md](../../../scripts/azure/README.md).  
Release ACA + AKS juntos: `.\Deploy-AzureShopDemo.ps1 -Mode All`.

Los pasos manuales siguientes (§2–§11) explican cada recurso si prefieres Portal/CLI paso a paso.

---

## 1. Variables del laboratorio

```bash
$RG = "rg-shopdemo-lab"
$LOCATION = "eastus"
$ACR_NAME = "acrshopdemolab01"   # † mismo nombre que .env.azure.example
$AKS_NAME = "aks-shopdemo"
```

---

## 2. Paso 1 — Resource Group y ACR

**Objetivo:** Registro de imágenes (reutilizar ACR de ACA si existe).

### Portal Azure

1. **Resource groups** → `rg-shopdemo-lab` (mismo RG que ACA; o crear uno dedicado si prefieres)
2. **Container Registry** → crear o seleccionar `acrshopdemolab01` (mismo ACR del release ACA)

### CLI

```bash
az group create --name $RG --location $LOCATION
az acr create --resource-group $RG --name $ACR_NAME --sku Basic
```

---

## 3. Paso 2 — Crear cluster AKS

**Objetivo:** Cluster con 1–2 nodos para el lab.

### Portal Azure

1. **Kubernetes services** → **Create**
2. **Basics:** name `aks-shopdemo`, region, RG
3. **Node pools:** 1 pool, tamaño `Standard_B2s`, count `1`
4. **Integrations:** habilitar **Container Registry** → seleccionar ACR
5. **Networking:** defaults (Azure CNI o overlay según wizard)
6. **Create** (10–15 min)

### CLI

```bash
az aks create \
  --resource-group $RG \
  --name $AKS_NAME \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys

az aks show --resource-group $RG --name $AKS_NAME --query provisioningState
```

**Explicación:** `--attach-acr` evita `ImagePullBackOff` por permisos.

---

## 4. Paso 3 — Conectar kubectl

### Portal

1. AKS cluster → **Connect** → copiar comandos `az aks get-credentials`

### CLI

```bash
az aks get-credentials --resource-group $RG --name $AKS_NAME
kubectl get nodes
```

---

## 5. Paso 4 — Build y push a ACR

**Objetivo:** Imágenes en la nube (no locales).

```bash
cd I:\Curso\ShopDemo
az acr login --name $ACR_NAME
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv

$images = @(
  @{ df = "Catalog/ShopDemo.Catalog.Api/Dockerfile"; img = "shopdemo-catalog" }
  @{ df = "Orders/ShopDemo.Orders.Api/Dockerfile"; img = "shopdemo-orders" }
  @{ df = "Inventory/ShopDemo.Inventory.Api/Dockerfile"; img = "shopdemo-inventory" }
  @{ df = "Aspire/ShopDemo.Analytics.Api/Dockerfile"; img = "shopdemo-analytics" }
  @{ df = "AI/ShopDemo.Mcp.Api/Dockerfile"; img = "shopdemo-mcp" }
)
foreach ($i in $images) {
  docker build -f $i.df -t "$ACR_LOGIN/$($i.img):v1" .
  docker push "$ACR_LOGIN/$($i.img):v1"
}
```

---

## 6. Paso 5 — Instalar Ingress NGINX (Helm)

**Objetivo:** Controlador Ingress en AKS. En nube se usa **Helm**, no el addon de Minikube.

### Portal (Marketplace)

1. Buscar **NGINX Ingress Controller** o usar Helm desde Cloud Shell

### CLI (Helm)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
kubectl get svc -n ingress-nginx
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

**Explicación:** Helm instala el chart oficial con Service tipo LoadBalancer; Azure asigna IP pública automáticamente.

---

## 7. Paso 6 — Ajustar manifiestos para ACR

**Objetivo:** Cambiar `image: shopdemo-catalog:latest` por ACR.

Opción rápida — script para los **5 deployments**:

```bash
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv
$tag = "v1"
$services = @("catalog","orders","inventory","analytics","mcp")
foreach ($svc in $services) {
  $path = "k8s/$svc/deployment.yaml"
  (Get-Content $path) -replace "shopdemo-${svc}:latest", "$ACR_LOGIN/shopdemo-${svc}:$tag" |
    Set-Content "k8s/$svc/deployment-aks.yaml"
}
```

O editar cada `k8s/*/deployment.yaml` con la ruta completa ACR y `imagePullPolicy: Always`.

---

## 8. Paso 7 — Desplegar ShopDemo

Orden canónico (igual que [k8s/README.md](../../../k8s/README.md)):

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl wait --for=condition=ready pod -l app=shopdemo-postgres -n shopdemo --timeout=300s

# APIs + MCP (usar deployment-aks.yaml si generaste parches ACR)
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/inventory/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/analytics/
kubectl apply -f k8s/mcp/
kubectl apply -f k8s/catalog/hpa.yaml
kubectl apply -f k8s/ingress/

kubectl get pods -n shopdemo
kubectl get ingress -n shopdemo
```

---

## 9. Paso 8 — Secrets, Probes y HPA

### 9.1 Kubernetes Secrets

| Paso | Acción |
|---|---|
| 1 | En tu máquina: `copy k8s\secrets.example.yaml k8s\secrets.yaml` |
| 2 | Completar `EVENT_HUBS_CONNECTION_STRING` |
| 3 | `kubectl apply -f k8s/secrets.yaml` |
| 4 | Verificar: `kubectl describe secret shopdemo-secrets -n shopdemo` |

Los Deployments referencian el Secret con `secretKeyRef` — mismos YAML que Minikube.

### 9.2 Liveness y Readiness

Tras desplegar, comprobar probes HTTP:

```bash
kubectl get pods -n shopdemo
kubectl describe pod -n shopdemo -l app=shopdemo-catalog
```

Debe aparecer `Readiness: http-get /health` y `Liveness: http-get /alive` en estado **Success**.

Si fallan tras el primer deploy:

```bash
# Rebuild y push imagen con /health
kubectl rollout restart deployment/shopdemo-catalog -n shopdemo
```

### 9.3 Autoscaling (HPA)

AKS incluye **metrics-server** por defecto en versiones recientes.

```bash
kubectl apply -f k8s/catalog/hpa.yaml
kubectl get hpa -n shopdemo
```

| Campo HPA | Valor |
|---|---|
| minReplicas | 1 |
| maxReplicas | 3 |
| CPU target | 70 % |

---

## 10. Paso 9 — Testeo

```bash
$INGRESS_IP = kubectl get ingress shopdemo-ingress -n shopdemo -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo "http://$INGRESS_IP/catalog/swagger"

kubectl get pods -n shopdemo
kubectl logs -n shopdemo -l app=shopdemo-catalog --tail=50
```

Flujo E2E: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) (ajustar URLs al Ingress).

| Prueba | Esperado |
|---|---|
| Pods | Todos `Running` |
| Probes | `/health` y `/alive` Success |
| HPA | `shopdemo-catalog-hpa` con TARGETS numérico |
| Crear producto | `201` Catalog |
| Analytics | Eventos en `/analytics/api/analytics/events` |
| Confirmar pedido | `200` Orders |

---

## 11. Paso 10 — Limpieza

### Portal

Resource Group → **Delete resource group**

### CLI

```bash
az group delete --name $RG --yes --no-wait
```

---

## Errores comunes (AKS)

Ver [TEORIA-AKS.md](./TEORIA-AKS.md) §4.

---

## Referencias

- [TEORIA-AKS.md](./TEORIA-AKS.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) (ACR compartido)
