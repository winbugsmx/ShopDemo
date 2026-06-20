# Implementación — Despliegue de contenedores en Azure (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Plataforma:** Azure Container Apps + ACR + ACI  
**Versión:** 1.0

> Cada paso incluye **dos enfoques**: configuración por **Portal Azure** y por **Azure CLI**, para que el alumno elija el que prefiera.

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 7)  
**Script automatizado (CLI):** [scripts/azure/README.md](../../../scripts/azure/README.md) — `Deploy-AzureShopDemo.ps1` / `Remove-AzureShopDemo.ps1`  
**Qué integrar:** `Dockerfile` y `docker-compose.yml` de cada API (ya en el repo); variables de entorno y secretos en ACA — **sin código C# nuevo**.

### Arquitectura de checkpoints (importante)

| Entorno | Almacén de checkpoints Event Hubs | Servicio Azure/AWS |
|---|---|---|
| **ACA (release serverless)** | **Azure Storage Account** (Blob) | `STORAGE_ACCOUNT_NAME` — contenedores `inventory-checkpoints`, `analytics-checkpoints` |
| **AKS / Minikube / EKS** | **Azurite** in-cluster | Manifiesto `k8s/azurite/` |
| **ECS Fargate** | **Azurite** en tarea Fargate | Service `shopdemo-azurite` |

> Los pasos manuales §7–§13 de este documento siguen la **misma arquitectura que el script** `Deploy-AzureShopDemo.ps1` (Storage Account en ACA, no Azurite ACI).

### Convención de nombres del laboratorio (usar siempre estos valores)

> Los nombres marcados con **†** deben ser **únicos globalmente** en Azure. Si ya están ocupados, cambia solo el sufijo numérico (`01` → `02`) en **todos** los pasos y en `scripts/azure/.env.azure`.

| Recurso Azure | Nombre canónico | Variable `.env.azure` | Para qué sirve |
|---|---|---|---|
| Resource Group | `rg-shopdemo-lab` | `RESOURCE_GROUP` | Agrupa todos los recursos del lab para borrarlos juntos |
| Región | `eastus` | `AZURE_LOCATION` | Ubicación geográfica de los recursos |
| Event Hubs namespace † | `shopdemo-eh-ns-lab01` | `EVENT_HUB_NAMESPACE` | Bus de mensajería entre microservicios |
| Event Hub | `shopdemo-events` | `EVENT_HUB_NAME` | Canal único de eventos del curso |
| Consumer groups | `inventory-service`, `analytics-service` | — | Lectura independiente por Inventory y Analytics |
| Container Registry † | `acrshopdemolab01` | `ACR_NAME` | Almacena imágenes Docker (`shopdemo-*`) |
| Log Analytics | `log-shopdemo` | `LOG_ANALYTICS_NAME` | Recolecta logs de Container Apps |
| ACA Environment | `aca-env-shopdemo` | `ACA_ENV_NAME` | Entorno de ejecución de las 5 Container Apps |
| PostgreSQL ACI | `aci-shopdemo-postgres` | `POSTGRES_ACI_NAME` | Base de datos en contenedor (3 bases) |
| DNS label PostgreSQL | `shopdemo-pg-lab` | `POSTGRES_DNS_LABEL` | FQDN público del ACI PostgreSQL |
| Storage Account † | `shopdemochecklab01` | `STORAGE_ACCOUNT_NAME` | Checkpoints Blob de Event Hubs (ACA) |
| Contenedores Blob | `inventory-checkpoints`, `analytics-checkpoints` | — | Carpetas dentro del Storage Account |
| Container App Catalog | `ca-shopdemo-catalog` | — | API pública de catálogo |
| Container App Inventory | `ca-shopdemo-inventory` | — | API **interna** de inventario |
| Container App Orders | `ca-shopdemo-orders` | — | API pública de pedidos |
| Container App Analytics | `ca-shopdemo-analytics` | — | API observador de eventos |
| Container App MCP | `ca-shopdemo-mcp` | — | Gateway para agentes IA (`/mcp`) |
| Imágenes en ACR | `shopdemo-catalog`, `shopdemo-orders`, … | `IMAGE_TAG` | Tags Docker (por defecto `latest`) |

**Login server ACR esperado:** `acrshopdemolab01.azurecr.io`

---

## Índice

0. [**Script PowerShell automatizado (recomendado)**](#0-script-powershell-automatizado-recomendado)
1. [Prerequisitos](#1-prerequisitos)
2. [Variables del laboratorio](#2-variables-del-laboratorio)
3. [Paso 1 — Resource Group](#3-paso-1--resource-group)
4. [Paso 2 — Azure Container Registry](#4-paso-2--azure-container-registry)
5. [Paso 3 — Log Analytics y Container Apps Environment](#5-paso-3--log-analytics-y-container-apps-environment)
6. [Paso 4 — PostgreSQL en contenedor (ACI)](#6-paso-4--postgresql-en-contenedor-aci)
7. [Paso 5 — Storage Account (checkpoints ACA)](#7-paso-5--storage-account-checkpoints-aca)
8. [Paso 6 — Build y push de imágenes (5 servicios)](#8-paso-6--build-y-push-de-imágenes-5-servicios)
9. [Paso 7 — Secretos en Container Apps](#9-paso-7--secretos-en-container-apps)
10. [Paso 8 — Desplegar Catalog](#10-paso-8--desplegar-catalog)
11. [Paso 9 — Desplegar Inventory](#11-paso-9--desplegar-inventory)
12. [Paso 10 — Desplegar Orders](#12-paso-10--desplegar-orders)
13. [Paso 11 — Desplegar Analytics](#13-paso-11--desplegar-analytics)
14. [Paso 12 — Desplegar MCP Gateway](#14-paso-12--desplegar-mcp-gateway)
15. [Paso 13 — Probar el flujo](#15-paso-13--probar-el-flujo)
16. [Paso 14 — GitHub Actions (CI/CD)](#16-paso-14--github-actions-cicd)
17. [Paso 15 — Limpieza de recursos](#17-paso-15--limpieza-de-recursos)
18. [Solución de problemas](#18-solución-de-problemas)

---

## 0. Script PowerShell automatizado (recomendado)

Para el laboratorio del curso puedes **provisionar casi toda la infraestructura Azure** con un solo script, en lugar de repetir cada paso del Portal/CLI manualmente.

| Recurso | Ruta |
|---|---|
| Scripts | [scripts/azure/](../../../scripts/azure/) |
| Guía detallada | [scripts/azure/README.md](../../../scripts/azure/README.md) |
| Plantilla de variables | [scripts/azure/.env.azure.example](../../../scripts/azure/.env.azure.example) |

> El script **no construye imágenes Docker**. Después de ejecutarlo debes publicar las imágenes en ACR (GitHub Actions o build manual, §8 y §15).

### Cuándo usar cada modo

| Modo | Comando | Qué crea | Etapa del curso |
|---|---|---|---|
| **ACA** | `.\Deploy-AzureShopDemo.ps1 -Mode ACA` | Event Hubs, Storage, ACR, PostgreSQL (ACI), 5 Container Apps + MCP | 7 + 14b |
| **AKS** | `.\Deploy-AzureShopDemo.ps1 -Mode AKS` | Event Hubs, ACR, cluster AKS, Ingress Helm, `k8s/secrets.yaml` | 10 |
| **All** | `.\Deploy-AzureShopDemo.ps1 -Mode All` | ACA + AKS (lab completo) | 7 + 10 |

Los pasos manuales de este documento (§3–§13) siguen siendo válidos para **entender** cada recurso o si prefieres el Portal.

### Paso A — Configurar variables (`.env.azure`)

```powershell
cd I:\Curso\ShopDemo\scripts\azure
copy .env.azure.example .env.azure
notepad .env.azure
```

| Variable | Obligatorio | Dónde obtenerlo |
|---|---|---|
| `AZURE_SUBSCRIPTION_ID` | Sí | Portal → **Subscriptions** → **Subscription ID** |
| `AZURE_LOCATION` | Sí | Región del lab (`eastus`, `mexicocentral`, …) |
| `RESOURCE_GROUP` | Sí | Nombre que eliges (ej. `rg-shopdemo-lab`) |
| `ACR_NAME` | Sí | **Único global** en Azure; solo `a-z` y `0-9` |
| `EVENT_HUB_NAMESPACE` | Sí | **Único global**; el script lo crea si no existe |
| `STORAGE_ACCOUNT_NAME` | Sí | **Único global**; checkpoints en ACA |
| `POSTGRES_PASSWORD` | Sí | La defines tú (lab) |
| `POSTGRES_DNS_LABEL` | Sí | Etiqueta DNS del ACI PostgreSQL (única en región) |
| `AKS_CLUSTER_NAME` | Solo AKS/All | Nombre del cluster |

El script obtiene solo: connection strings de Event Hubs y Storage, FQDN de PostgreSQL y Container Apps.

### Paso B — Login y ejecución

```powershell
az login
az account set --subscription "<TU-SUBSCRIPTION-ID>"

# Container Apps (release serverless)
.\Deploy-AzureShopDemo.ps1 -Mode ACA

# O Kubernetes en Azure
.\Deploy-AzureShopDemo.ps1 -Mode AKS

# O ambos
.\Deploy-AzureShopDemo.ps1 -Mode All
```

Al finalizar, el script imprime las **URLs** de cada Container App (modo ACA) y las instrucciones para `kubectl apply` (modo AKS).

### Paso C — Publicar imágenes en ACR (obligatorio)

El script crea el registro pero **no hace push**. Opciones:

| Opción | Cómo |
|---|---|
| **GitHub Actions** | Configura secrets en el repo (§15) y ejecuta [.github/workflows/deploy-azure.yml](../../../.github/workflows/deploy-azure.yml) |
| **Manual** | `docker build` + `docker push` — ver [§8 Build y push](#8-paso-6--build-y-push-de-imágenes) |

Imágenes requeridas con tag `IMAGE_TAG` (por defecto `latest`):

`shopdemo-catalog` · `shopdemo-orders` · `shopdemo-inventory` · `shopdemo-analytics` · `shopdemo-mcp`

### Paso D — Validar release

| Modo | Verificación |
|---|---|
| **ACA** | `curl https://<fqdn-catalog>/health` · Swagger · carpeta Postman **Health checks** |
| **AKS** | Editar `k8s/*/deployment.yaml` con `<acr>.azurecr.io/shopdemo-*:latest` → `kubectl apply -f k8s/` (orden en [k8s/README.md](../../../k8s/README.md)) |

Guía de endpoints: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) (sustituir `localhost` por FQDN ACA o Ingress).

### Paso E — Limpieza del laboratorio

```powershell
.\Remove-AzureShopDemo.ps1
# Confirma escribiendo el nombre del Resource Group
```

Borra el Resource Group completo (`RESOURCE_GROUP` en `.env.azure`). Ver también [§17 Limpieza](#17-paso-15--limpieza-de-recursos).

### Relación script ↔ secciones manuales de este documento

| Script (interno) | Equivalente manual |
|---|---|
| Resource Group + Event Hubs + Storage | §3, [INTEGRACION-AZURE-EVENT-HUBS](../../INTEGRACION-AZURE-EVENT-HUBS.md) |
| ACR | §4 |
| Log Analytics + ACA Environment | §5 |
| PostgreSQL ACI | §6 |
| 5 Container Apps | §8–§12 + [MCP §14](#14-paso-12--desplegar-mcp-gateway) |
| AKS + `k8s/secrets.yaml` | [IMPLEMENTACION-DESPLIEGUE-AKS](../aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |

---

## 1. Prerequisitos

- Cuenta Azure con suscripción activa
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) instalado
- Docker Desktop funcionando
- Repositorio ShopDemo clonado
- Event Hubs creado: [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
- Login en Azure:

```bash
az login
az account set --subscription "<NOMBRE_O_ID_SUSCRIPCION>"
```

### Verificar imágenes locales (opcional)

```bash
cd I:\Curso\ShopDemo\Catalog\ShopDemo.Catalog.Api
docker compose build
```

---

## 2. Variables del laboratorio

Usa **exactamente** los nombres de la tabla anterior. Copia también en `scripts/azure/.env.azure` si usarás el script.

```powershell
# PowerShell — nombres canónicos del curso
$RG = "rg-shopdemo-lab"
$LOCATION = "eastus"
$ACR_NAME = "acrshopdemolab01"              # † único global
$ACA_ENV = "aca-env-shopdemo"
$LOG_WS = "log-shopdemo"
$EH_NAMESPACE = "shopdemo-eh-ns-lab01"      # † único global
$EH_NAME = "shopdemo-events"
$STORAGE_NAME = "shopdemochecklab01"        # † único global
$PG_ACI = "aci-shopdemo-postgres"
$PG_DNS = "shopdemo-pg-lab"
$PG_PASSWORD = "ShopDemo123!"

$EH_CONN = "<EVENT_HUBS_CONNECTION_STRING>"   # tras crear namespace (abajo)
```

```bash
# Bash
export RG="rg-shopdemo-lab"
export LOCATION="eastus"
export ACR_NAME="acrshopdemolab01"
export ACA_ENV="aca-env-shopdemo"
export LOG_WS="log-shopdemo"
export EH_NAMESPACE="shopdemo-eh-ns-lab01"
export EH_NAME="shopdemo-events"
export STORAGE_NAME="shopdemochecklab01"
export PG_ACI="aci-shopdemo-postgres"
export PG_DNS="shopdemo-pg-lab"
export PG_PASSWORD="ShopDemo123!"
export EH_CONN="<EVENT_HUBS_CONNECTION_STRING>"
```

### Event Hubs — Enfoque A (Portal Azure)

**Para qué sirve:** bus de eventos que conecta Catalog, Orders, Inventory y Analytics sin acoplamiento HTTP directo.

1. [portal.azure.com](https://portal.azure.com) → **Create a resource** → **Event Hubs**
2. **Namespace name:** `shopdemo-eh-ns-lab01` († si está ocupado, usa `shopdemo-eh-ns-lab02` y el mismo nombre en CLI/script)
3. **Resource group:** `rg-shopdemo-lab`
4. **Location:** `East US` (misma región que el resto)
5. **Pricing tier:** Basic → **Create**
6. Dentro del namespace → **Event Hubs** → **+ Event Hub** → Name: `shopdemo-events` → **Create**
7. **Event Hubs** → `shopdemo-events` → **Consumer groups** → crear:
   - `inventory-service`
   - `analytics-service`
8. Namespace → **Shared access policies** → **RootManageSharedAccessKey** → copiar **Primary Connection String** → variable `$EH_CONN`

Guía ampliada: [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md#4-crear-recursos-en-azure-portal).

### Event Hubs — Enfoque B (Azure CLI)

```bash
az eventhubs namespace create \
  --resource-group $RG --name $EH_NAMESPACE --location $LOCATION --sku Basic

az eventhubs eventhub create \
  --resource-group $RG --namespace-name $EH_NAMESPACE --name $EH_NAME --partition-count 2

az eventhubs eventhub consumer-group create \
  --resource-group $RG --namespace-name $EH_NAMESPACE \
  --eventhub-name $EH_NAME --name inventory-service

az eventhubs eventhub consumer-group create \
  --resource-group $RG --namespace-name $EH_NAMESPACE \
  --eventhub-name $EH_NAME --name analytics-service

$EH_CONN = az eventhubs namespace authorization-rule keys list \
  --resource-group $RG --namespace-name $EH_NAMESPACE \
  --name RootManageSharedAccessKey --query primaryConnectionString -o tsv
```

---

## 3. Paso 1 — Resource Group

**Para qué sirve:** contenedor lógico que agrupa **todos** los recursos del laboratorio; al borrarlo se elimina el lab completo.

**Nombre:** `rg-shopdemo-lab` (variable `$RG`)

### Enfoque A — Portal Azure

1. Ir a [portal.azure.com](https://portal.azure.com)
2. Buscar **Resource groups** → **Create**
3. **Subscription:** la del curso
4. **Resource group name:** `rg-shopdemo-lab`
5. **Region:** `East US` (o la más cercana)
6. **Review + Create** → **Create**

### Enfoque B — Azure CLI

```bash
az group create --name $RG --location $LOCATION
```

**Verificación:**

```bash
az group show --name $RG --query name -o tsv
```

---

## 4. Paso 2 — Azure Container Registry

**Para qué sirve:** registro **privado** donde se guardan las 5 imágenes Docker antes de desplegarlas en Container Apps.

**Nombre:** `acrshopdemolab01` (variable `$ACR_NAME`) · Login server: `acrshopdemolab01.azurecr.io`

### Enfoque A — Portal Azure

1. **Create a resource** → buscar **Container Registry**
2. **Registry name:** `acrshopdemolab01` († único global; si ocupado, `acrshopdemolab02` en todo el doc)
3. **Resource group:** `rg-shopdemo-lab`
4. **Location:** misma región
5. **SKU:** Basic
6. **Admin user:** Disabled (usaremos `az acr login`)
7. **Review + create** → **Create**

### Enfoque B — Azure CLI

```bash
az acr create \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled false
```

**Login al registro:**

```bash
az acr login --name $ACR_NAME
```

**Verificación:**

```bash
az acr show --name $ACR_NAME --query loginServer -o tsv
# Salida esperada: acrshopdemolab01.azurecr.io
```

---
```

---

## 5. Paso 3 — Log Analytics y Container Apps Environment

**Para qué sirve:** el **Environment** (`aca-env-shopdemo`) es el plano de ejecución compartido por las 5 Container Apps; **Log Analytics** (`log-shopdemo`) centraliza sus logs.

| Recurso | Nombre |
|---|---|
| Log Analytics workspace | `log-shopdemo` (`$LOG_WS`) |
| Container Apps Environment | `aca-env-shopdemo` (`$ACA_ENV`) |

### Enfoque A — Portal Azure

1. **Create a resource** → **Container Apps Environment**
2. **Environment name:** `aca-env-shopdemo`
3. **Region:** misma que el RG
4. **Logs:** crear nuevo **Log Analytics workspace** → `log-shopdemo`
5. **Create**

### Enfoque B — Azure CLI

```bash
# Workspace de logs
az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $LOG_WS

$LOG_ID = az monitor log-analytics workspace show \
  --resource-group $RG --workspace-name $LOG_WS --query customerId -o tsv

$LOG_KEY = az monitor log-analytics workspace get-shared-keys \
  --resource-group $RG --workspace-name $LOG_WS --query primarySharedKey -o tsv

# Environment de Container Apps
az containerapp env create \
  --name $ACA_ENV \
  --resource-group $RG \
  --location $LOCATION \
  --logs-workspace-id $LOG_ID \
  --logs-workspace-key $LOG_KEY
```

**Verificación:**

```bash
az containerapp env show --name $ACA_ENV --resource-group $RG --query properties.provisioningState
```

---

## 6. Paso 4 — PostgreSQL en contenedor (ACI)

**Para qué sirve:** base de datos PostgreSQL en un contenedor Azure (enfoque lab); aloja `ShopDemoCatalog`, `ShopDemoOrders` y `ShopDemoInventory`.

| Campo Portal | Valor |
|---|---|
| Container instance name | `aci-shopdemo-postgres` (`$PG_ACI`) |
| DNS name label | `shopdemo-pg-lab` (`$PG_DNS`) |
| Image | `postgres:16-alpine` |

### Enfoque A — Portal Azure

1. **Create a resource** → **Container Instances**
2. **Basics:**
   - Name: `aci-shopdemo-postgres`
   - Region: misma región
   - Image: `postgres:16-alpine`
   - OS: Linux
   - Size: 1 vCPU, 1.5 GB
3. **Networking:** Public IP → DNS name label: `shopdemo-pg-lab` (opcional)
4. **Advanced:**
   - Environment variables:
     - `POSTGRES_USER` = `ShopDemo`
     - `POSTGRES_PASSWORD` = `<tu-password>`
     - `POSTGRES_DB` = `postgres`
   - Port: `5432` TCP
5. **Create**

> Tras crear el contenedor, conecta con un cliente y ejecuta:
> `CREATE DATABASE "ShopDemoCatalog";`
> `CREATE DATABASE "ShopDemoOrders";`
> `CREATE DATABASE "ShopDemoInventory";`

### Enfoque B — Azure CLI

```bash
az container create \
  --resource-group $RG \
  --name $PG_ACI \
  --image postgres:16-alpine \
  --cpu 1 --memory 1.5 \
  --ports 5432 \
  --ip-address Public \
  --dns-name-label $PG_DNS \
  --environment-variables POSTGRES_USER=ShopDemo POSTGRES_PASSWORD=$PG_PASSWORD \
  --location $LOCATION

$PG_FQDN = az container show --resource-group $RG --name $PG_ACI \
  --query ipAddress.fqdn -o tsv

echo "PostgreSQL FQDN: $PG_FQDN"
```

Crear las tres bases (desde máquina con `psql` o Azure Cloud Shell):

```bash
psql "host=$PG_FQDN port=5432 user=ShopDemo password=$PG_PASSWORD dbname=postgres sslmode=require" \
  -c 'CREATE DATABASE "ShopDemoCatalog"; CREATE DATABASE "ShopDemoOrders"; CREATE DATABASE "ShopDemoInventory";'
```

**Cadena de conexión (plantilla por servicio):**

```
Host=<PG_FQDN>;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=<password>;Ssl Mode=Require
```

---

## 7. Paso 5 — Storage Account (checkpoints ACA)

**Para qué sirve:** almacenamiento Blob de Azure donde Inventory y Analytics guardan **checkpoints** de Event Hubs (posición de lectura del stream).

**Nombre:** `shopdemochecklab01` (variable `$STORAGE_NAME`) · Contenedores: `inventory-checkpoints`, `analytics-checkpoints`

> **No uses Azurite ACI en ACA** — Azurite es para Kubernetes (`k8s/azurite/`) y ECS Fargate.

### Enfoque A — Portal Azure

1. **Create a resource** → **Storage account**
2. **Storage account name:** `shopdemochecklab01` († único global)
3. **Resource group:** `rg-shopdemo-lab`
4. **Region:** misma que el RG
5. **Performance:** Standard · **Redundancy:** LRS
6. **Create**
7. En el storage → **Containers** → crear:
   - `inventory-checkpoints`
   - `analytics-checkpoints`

### Enfoque B — Azure CLI

```bash
az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS

$STORAGE_CONN = az storage account show-connection-string \
  --name $STORAGE_NAME \
  --resource-group $RG \
  --query connectionString -o tsv

az storage container create --name inventory-checkpoints \
  --account-name $STORAGE_NAME --auth-mode login

az storage container create --name analytics-checkpoints \
  --account-name $STORAGE_NAME --auth-mode login

echo "Storage connection string obtenida (usar como secreto storage-checkpoint)"
```

**Verificación:**

```bash
az storage container list --account-name $STORAGE_NAME --auth-mode login -o table
```

### Nota — Azurite (solo Kubernetes / ECS)

| Entorno | Checkpoints |
|---|---|
| ACA (este documento) | Storage Account (`storage-checkpoint`) |
| AKS / Minikube | `kubectl apply -f k8s/azurite/` |
| ECS AWS | Tarea Fargate Azurite — [IMPLEMENTACION-DESPLIEGUE-AWS §11](../aws/IMPLEMENTACION-DESPLIEGUE-AWS.md#11-paso-9--azurite-en-ecs) |

---

## 8. Paso 6 — Build y push de imágenes (5 servicios)

**Para qué sirve:** publicar las imágenes Docker en ACR para que las Container Apps puedan descargarlas al arrancar.

| Imagen ACR | Dockerfile |
|---|---|
| `shopdemo-catalog` | `Catalog/ShopDemo.Catalog.Api/Dockerfile` |
| `shopdemo-orders` | `Orders/ShopDemo.Orders.Api/Dockerfile` |
| `shopdemo-inventory` | `Inventory/ShopDemo.Inventory.Api/Dockerfile` |
| `shopdemo-analytics` | `Aspire/ShopDemo.Analytics.Api/Dockerfile` |
| `shopdemo-mcp` | `AI/ShopDemo.Mcp.Api/Dockerfile` |

Contexto de build = **raíz del repositorio** (como en `docker-compose`).

### Enfoque A — Portal Azure (build en la nube)

1. En ACR → **Tasks** → **Quick task**
2. Conectar repositorio GitHub (opcional) o usar **ACR Build** local:

   En la práctica del curso se recomienda **Enfoque B (CLI local)** por simplicidad.

### Enfoque B — Azure CLI + Docker local

```bash
cd I:\Curso\ShopDemo
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv

# Catalog
docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $ACR_LOGIN/shopdemo-catalog:latest .
docker push $ACR_LOGIN/shopdemo-catalog:latest

# Orders
docker build -f Orders/ShopDemo.Orders.Api/Dockerfile -t $ACR_LOGIN/shopdemo-orders:latest .
docker push $ACR_LOGIN/shopdemo-orders:latest

# Inventory
docker build -f Inventory/ShopDemo.Inventory.Api/Dockerfile -t $ACR_LOGIN/shopdemo-inventory:latest .
docker push $ACR_LOGIN/shopdemo-inventory:latest

# Analytics
docker build -f Aspire/ShopDemo.Analytics.Api/Dockerfile -t $ACR_LOGIN/shopdemo-analytics:latest .
docker push $ACR_LOGIN/shopdemo-analytics:latest

# MCP Gateway
docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t $ACR_LOGIN/shopdemo-mcp:latest .
docker push $ACR_LOGIN/shopdemo-mcp:latest
```

**Alternativa — build directo en ACR (sin Docker local):**

```bash
az acr build --registry $ACR_NAME --image shopdemo-catalog:latest \
  --file Catalog/ShopDemo.Catalog.Api/Dockerfile .
```

Repetir cambiando Dockerfile e imagen para cada servicio.

**Verificación:**

```bash
az acr repository list --name $ACR_NAME -o table
```

---

## 9. Paso 7 — Secretos en Container Apps

**Para qué sirve:** almacenar connection strings y claves fuera de las variables de entorno en texto plano; cada Container App referencia secretos por nombre.

En CLI se pasan al crear cada Container App (`--secrets` / `--secret-env-vars`). En Portal: **Secrets** de cada app.

| Secreto | Uso |
|---|---|
| `eh-connection` | Event Hubs connection string |
| `pg-catalog-conn` | Connection string Catalog |
| `pg-orders-conn` | Connection string Orders |
| `pg-inventory-conn` | Connection string Inventory |
| `azurite-checkpoint` | *(solo K8s/ECS — no ACA)* |
| `storage-checkpoint` | Connection string Storage Account (checkpoints Blob) |

> En Portal: Container App → **Containers** → **Edit and deploy** → pestaña **Secrets**.

---

## 10. Paso 8 — Desplegar Catalog

**Para qué sirve:** primera API de negocio pública; valida ACR, PostgreSQL y Event Hubs.

| Campo | Valor |
|---|---|
| Container App name | `ca-shopdemo-catalog` |
| Environment | `aca-env-shopdemo` |
| Imagen | `acrshopdemolab01.azurecr.io/shopdemo-catalog:latest` |
| Ingress | External, puerto `8080` |

### Enfoque A — Portal Azure

1. **Container Apps** → **Create**
2. **Basics:** name `ca-shopdemo-catalog`, environment `aca-env-shopdemo`
3. **Container:**
   - Image: `acrshopdemolab01.azurecr.io/shopdemo-catalog:latest`
   - Registry: seleccionar ACR
   - CPU/RAM: 0.5 / 1 Gi
   - Port: `8080`
4. **Ingress:** Enabled, External, Target port `8080`
5. **Environment variables:**
   - `ASPNETCORE_ENVIRONMENT` = `Production`
   - `ConnectionStrings__DefaultConnection` = secret `pg-catalog-conn`
   - `EventHubs__Enabled` = `true`
   - `EventHubs__ConnectionString` = secret `eh-connection`
   - `EventHubs__EventHubName` = `shopdemo-events`
6. **Create**

### Enfoque B — Azure CLI

```bash
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv
$ACR_PASS = az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv

$PG_CATALOG_CONN = "Host=$PG_FQDN;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=$PG_PASSWORD;Ssl Mode=Require"

az containerapp create \
  --name ca-shopdemo-catalog \
  --resource-group $RG \
  --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-catalog:latest" \
  --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASS \
  --target-port 8080 \
  --ingress external \
  --min-replicas 0 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi \
  --secrets eh-connection="$EH_CONN" pg-catalog-conn="$PG_CATALOG_CONN" \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    ConnectionStrings__DefaultConnection=secretref:pg-catalog-conn \
    EventHubs__Enabled=true \
    EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events
```

**Verificación:**

```bash
$CATALOG_URL = az containerapp show --name ca-shopdemo-catalog --resource-group $RG \
  --query properties.configuration.ingress.fqdn -o tsv
echo "https://$CATALOG_URL/swagger"
```

---

## 11. Paso 9 — Desplegar Inventory

**Para qué sirve:** API de stock con ingress **interno**; Orders la consume por URL privada. Consume Event Hubs y guarda checkpoints en Storage.

| Campo | Valor |
|---|---|
| Container App name | `ca-shopdemo-inventory` |
| Ingress | **Internal only**, puerto `8080` |
| Consumer group | `inventory-service` |
| Checkpoint container | `inventory-checkpoints` |

### Enfoque A — Portal Azure

1. Crear Container App `ca-shopdemo-inventory` en environment `aca-env-shopdemo`
2. Imagen: `acrshopdemolab01.azurecr.io/shopdemo-inventory:latest`
3. **Ingress:** Enabled, **Internal only**, port `8080`
4. Variables:
   - `ConnectionStrings__DefaultConnection` → secret PG Inventory
   - `EventHubs__Enabled` = `true`
   - `EventHubs__ConnectionString` → secret EH
   - `EventHubs__ConsumerGroup` = `inventory-service`
   - `EventHubs__CheckpointStorageConnectionString` → secret `storage-checkpoint`
   - `EventHubs__CheckpointContainerName` = `inventory-checkpoints`

### Enfoque B — Azure CLI

```bash
$PG_INVENTORY_CONN = "Host=$PG_FQDN;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=$PG_PASSWORD;Ssl Mode=Require"

az containerapp create \
  --name ca-shopdemo-inventory \
  --resource-group $RG \
  --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-inventory:latest" \
  --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASS \
  --target-port 8080 \
  --ingress internal \
  --min-replicas 1 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi \
  --secrets eh-connection="$EH_CONN" pg-inventory-conn="$PG_INVENTORY_CONN" storage-checkpoint="$STORAGE_CONN" \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    ConnectionStrings__DefaultConnection=secretref:pg-inventory-conn \
    EventHubs__Enabled=true \
    EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events \
    EventHubs__ConsumerGroup=inventory-service \
    EventHubs__CheckpointStorageConnectionString=secretref:storage-checkpoint \
    EventHubs__CheckpointContainerName=inventory-checkpoints

$INVENTORY_URL = az containerapp show --name ca-shopdemo-inventory --resource-group $RG \
  --query properties.configuration.ingress.fqdn -o tsv
echo "Inventory internal: https://$INVENTORY_URL"
```

---

## 12. Paso 10 — Desplegar Orders

**Para qué sirve:** API de pedidos pública; al confirmar un pedido llama a Inventory por su FQDN interno.

| Campo | Valor |
|---|---|
| Container App name | `ca-shopdemo-orders` |
| Ingress | External |
| Variable clave | `InventoryApi__BaseUrl` = `https://<fqdn-ca-shopdemo-inventory>` |

### Enfoque A — Portal Azure

1. Container App `ca-shopdemo-orders`, environment `aca-env-shopdemo`, ingress **External**
2. Variable clave:
   - `InventoryApi__BaseUrl` = `https://<fqdn-interno-inventory>`
3. Resto de secrets PG y Event Hubs igual que Catalog

### Enfoque B — Azure CLI

```bash
$PG_ORDERS_CONN = "Host=$PG_FQDN;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=$PG_PASSWORD;Ssl Mode=Require"

az containerapp create \
  --name ca-shopdemo-orders \
  --resource-group $RG \
  --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-orders:latest" \
  --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASS \
  --target-port 8080 \
  --ingress external \
  --min-replicas 0 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi \
  --secrets eh-connection="$EH_CONN" pg-orders-conn="$PG_ORDERS_CONN" \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    ConnectionStrings__DefaultConnection=secretref:pg-orders-conn \
    InventoryApi__BaseUrl="https://$INVENTORY_URL" \
    EventHubs__Enabled=true \
    EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events
```

---

## 13. Paso 11 — Desplegar Analytics

**Para qué sirve:** observador de eventos del bus; expone API para consultar eventos recibidos.

| Campo | Valor |
|---|---|
| Container App name | `ca-shopdemo-analytics` |
| Ingress | External |
| Consumer group | `analytics-service` |
| Checkpoint container | `analytics-checkpoints` |

### Enfoque A — Portal Azure

1. Container App `ca-shopdemo-analytics` en `aca-env-shopdemo`
2. Ingress External, imagen `acrshopdemolab01.azurecr.io/shopdemo-analytics:latest`
3. Variables Event Hubs + checkpoint (`analytics-service`, `analytics-checkpoints`)

### Enfoque B — Azure CLI

```bash
az containerapp create \
  --name ca-shopdemo-analytics \
  --resource-group $RG \
  --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-analytics:latest" \
  --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASS \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 --max-replicas 1 \
  --cpu 0.5 --memory 1.0Gi \
  --secrets eh-connection="$EH_CONN" storage-checkpoint="$STORAGE_CONN" \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    EventHubs__Enabled=true \
    EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events \
    EventHubs__ConsumerGroup=analytics-service \
    EventHubs__CheckpointStorageConnectionString=secretref:storage-checkpoint \
    EventHubs__CheckpointContainerName=analytics-checkpoints
```

---

## 14. Paso 12 — Desplegar MCP Gateway

**Para qué sirve:** expone el protocolo MCP (`/mcp`) para que agentes IA (Cursor, etc.) invoquen herramientas sobre Catalog, Inventory y Analytics.

| Campo | Valor |
|---|---|
| Container App name | `ca-shopdemo-mcp` |
| Ingress | External |
| Imagen | `acrshopdemolab01.azurecr.io/shopdemo-mcp:latest` |

### Enfoque A — Portal Azure

1. Container App `ca-shopdemo-mcp`, ingress **External**
2. Imagen: `shopdemo-mcp:latest`
3. Variables (sin secretos):
   - `ShopDemo__CatalogApiBaseUrl` = `https://<fqdn-catalog>`
   - `ShopDemo__InventoryApiBaseUrl` = `https://<fqdn-inventory-interno>`
   - `ShopDemo__AnalyticsApiBaseUrl` = `https://<fqdn-analytics>`

### Enfoque B — Azure CLI

```bash
$CATALOG_URL = az containerapp show --name ca-shopdemo-catalog --resource-group $RG \
  --query properties.configuration.ingress.fqdn -o tsv
$ANALYTICS_URL = az containerapp show --name ca-shopdemo-analytics --resource-group $RG \
  --query properties.configuration.ingress.fqdn -o tsv
# $INVENTORY_URL ya obtenido en paso Inventory

az containerapp create \
  --name ca-shopdemo-mcp \
  --resource-group $RG \
  --environment $ACA_ENV \
  --image "$ACR_LOGIN/shopdemo-mcp:latest" \
  --registry-server $ACR_LOGIN \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASS \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    ShopDemo__CatalogApiBaseUrl="https://$CATALOG_URL" \
    ShopDemo__InventoryApiBaseUrl="https://$INVENTORY_URL" \
    ShopDemo__AnalyticsApiBaseUrl="https://$ANALYTICS_URL"

$MCP_URL = az containerapp show --name ca-shopdemo-mcp --resource-group $RG \
  --query properties.configuration.ingress.fqdn -o tsv
echo "MCP: https://$MCP_URL/mcp"
```

Detalle adicional: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../../integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md).

---

## 15. Paso 13 — Probar el flujo

| # | Acción | Cómo |
|---|---|---|
| 1 | Abrir Swagger Catalog | `https://<catalog-fqdn>/swagger` |
| 2 | `POST /api/products` | Crear producto |
| 3 | Analytics | `GET https://<analytics-fqdn>/api/analytics/events` |
| 4 | Orders | Crear y confirmar pedido |
| 6 | MCP | `GET https://<mcp-fqdn>/health` |
| 7 | Ver logs | Portal → Container App → **Log stream** o Log Analytics |

Usa también [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) sustituyendo `localhost` por los FQDN de ACA.

---

## 16. Paso 14 — GitHub Actions (CI/CD)

**Objetivo:** Automatizar build, push a ACR y actualización de las **5 Container Apps**.

Archivo de referencia (copiar del repo): [.github/workflows/deploy-azure.yml](../../../.github/workflows/deploy-azure.yml)

### Configurar secrets en GitHub

| Secret | Valor |
|---|---|
| `AZURE_CREDENTIALS` | JSON de service principal (`az ad sp create-for-rbac`) |
| `ACR_NAME` | `acrshopdemolab01` |
| `AZURE_RG` | `rg-shopdemo-lab` |
| `ACA_ENV` | `aca-env-shopdemo` |

### Enfoque A — Portal Azure (Service Principal)

1. **Microsoft Entra ID** → **App registrations** → **New registration**
2. Crear secret en **Certificates & secrets**
3. Asignar rol **Contributor** al RG en **Access control (IAM)**

### Enfoque B — Azure CLI

```bash
az ad sp create-for-rbac --name "github-shopdemo" --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/$RG \
  --sdk-auth
```

Pegar salida JSON en GitHub secret `AZURE_CREDENTIALS`.

El workflow hace: checkout → login → build/push **5 imágenes** → `az containerapp update` por servicio (`ca-shopdemo-catalog`, `ca-shopdemo-orders`, `ca-shopdemo-inventory`, `ca-shopdemo-analytics`, `ca-shopdemo-mcp`).

---

## 17. Paso 15 — Limpieza de recursos

### Portal

1. Resource Group `rg-shopdemo-lab`
2. **Delete resource group** → confirmar nombre

### CLI

```bash
az group delete --name $RG --yes --no-wait
```

---

## 18. Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| `Image pull failed` | ACR sin credenciales en ACA | Revisar registry username/password en la app |
| API no arranca | Puerto incorrecto | Confirmar `target-port 8080` y `ASPNETCORE_URLS` en Dockerfile |
| Orders 502 al confirmar | URL Inventory incorrecta | Verificar `InventoryApi__BaseUrl` con FQDN **interno** |
| Sin eventos en Analytics | EH deshabilitado o consumer group | Revisar `EventHubs__Enabled`, grupo `analytics-service` y secreto `storage-checkpoint` |
| EF migration error | PG no accesible | Abrir puerto 5432 en ACI; revisar SSL en connection string |

---

## Referencias

- [TEORIA-CONTENEDORES-AZURE.md](./TEORIA-CONTENEDORES-AZURE.md)
- [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./REQUERIMIENTOS-DESPLIEGUE-AZURE.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
