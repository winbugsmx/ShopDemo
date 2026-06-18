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
**Qué integrar:** `Dockerfile` y `docker-compose.yml` de cada API (ya en el repo); variables de entorno y secretos en ACA — **sin código C# nuevo**.

---

## Índice

1. [Prerequisitos](#1-prerequisitos)
2. [Variables del laboratorio](#2-variables-del-laboratorio)
3. [Paso 1 — Resource Group](#3-paso-1--resource-group)
4. [Paso 2 — Azure Container Registry](#4-paso-2--azure-container-registry)
5. [Paso 3 — Log Analytics y Container Apps Environment](#5-paso-3--log-analytics-y-container-apps-environment)
6. [Paso 4 — PostgreSQL en contenedor (ACI)](#6-paso-4--postgresql-en-contenedor-aci)
7. [Paso 5 — Azurite en contenedor (ACI)](#7-paso-5--azurite-en-contenedor-aci)
8. [Paso 6 — Build y push de imágenes](#8-paso-6--build-y-push-de-imágenes)
9. [Paso 7 — Secretos en Container Apps](#9-paso-7--secretos-en-container-apps)
10. [Paso 8 — Desplegar Catalog](#10-paso-8--desplegar-catalog)
11. [Paso 9 — Desplegar Inventory](#11-paso-9--desplegar-inventory)
12. [Paso 10 — Desplegar Orders](#12-paso-10--desplegar-orders)
13. [Paso 11 — Desplegar Analytics](#13-paso-11--desplegar-analytics)
14. [Paso 12 — Probar el flujo](#14-paso-12--probar-el-flujo)
15. [Paso 13 — GitHub Actions (CI/CD)](#15-paso-13--github-actions-cicd)
16. [Paso 14 — Limpieza de recursos](#16-paso-14--limpieza-de-recursos)
17. [Solución de problemas](#17-solución-de-problemas)

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

Define estas variables (PowerShell o bash). Ajústalas a tu entorno:

```bash
# PowerShell
$RG = "rg-shopdemo-lab"
$LOCATION = "eastus"
$ACR_NAME = "acrshopdemolab"    # solo minúsculas y números, único globalmente
$ACA_ENV = "aca-env-shopdemo"
$LOG_WS = "log-shopdemo"

# Connection strings (completar)
$EH_CONN = "<EVENT_HUBS_CONNECTION_STRING>"
$PG_PASSWORD = "ShopDemo123!"
```

```bash
# Bash
export RG="rg-shopdemo-lab"
export LOCATION="eastus"
export ACR_NAME="acrshopdemolab"
export ACA_ENV="aca-env-shopdemo"
export LOG_WS="log-shopdemo"
export EH_CONN="<EVENT_HUBS_CONNECTION_STRING>"
export PG_PASSWORD="ShopDemo123!"
```

---

## 3. Paso 1 — Resource Group

**Objetivo:** Agrupar todos los recursos del laboratorio para poder eliminarlos de una vez.

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

**Objetivo:** Registro privado donde se almacenan las imágenes `shopdemo-*`.

### Enfoque A — Portal Azure

1. **Create a resource** → buscar **Container Registry**
2. **Registry name:** `acrshopdemolab` (único)
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
# Salida esperada: acrshopdemolab.azurecr.io
```

---

## 5. Paso 3 — Log Analytics y Container Apps Environment

**Objetivo:** Crear el entorno de ejecución donde vivirán las 4 Container Apps.

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

**Objetivo:** Base de datos en contenedor para las 3 APIs de negocio (enfoque lab).

Usaremos **una instancia PostgreSQL** con tres bases creadas al inicio.

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
  --name aci-shopdemo-postgres \
  --image postgres:16-alpine \
  --cpu 1 --memory 1.5 \
  --ports 5432 \
  --ip-address Public \
  --dns-name-label shopdemo-pg-lab \
  --environment-variables POSTGRES_USER=ShopDemo POSTGRES_PASSWORD=$PG_PASSWORD \
  --location $LOCATION

$PG_FQDN = az container show --resource-group $RG --name aci-shopdemo-postgres \
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

## 7. Paso 5 — Azurite en contenedor (ACI)

**Objetivo:** Emulador de Blob Storage para checkpoints de Event Hubs (Inventory y Analytics).

### Enfoque A — Portal Azure

1. **Container Instances** → **Create**
2. Name: `aci-shopdemo-azurite`
3. Image: `mcr.microsoft.com/azure-storage/azurite`
4. Ports: `10000` TCP, IP pública
5. **Command override:** `azurite-blob --blobHost 0.0.0.0 --blobPort 10000`
6. **Create**

### Enfoque B — Azure CLI

```bash
az container create \
  --resource-group $RG \
  --name aci-shopdemo-azurite \
  --image mcr.microsoft.com/azure-storage/azurite \
  --cpu 1 --memory 1 \
  --ports 10000 \
  --ip-address Public \
  --command-line "azurite-blob --blobHost 0.0.0.0 --blobPort 10000" \
  --location $LOCATION

$AZ_FQDN = az container show --resource-group $RG --name aci-shopdemo-azurite \
  --query ipAddress.fqdn -o tsv
```

**Connection string de checkpoint (lab):**

```
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://<AZ_FQDN>:10000/devstoreaccount1;
```

---

## 8. Paso 6 — Build y push de imágenes

**Objetivo:** Construir las 4 imágenes desde el repo y subirlas a ACR.

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

**Objetivo:** Centralizar valores sensibles antes de crear las apps.

En CLI se pasan al crear cada Container App (`--secrets` / `--secret-env-vars`). En Portal se configuran en **Secrets** de cada app.

| Secreto | Uso |
|---|---|
| `eh-connection` | Event Hubs connection string |
| `pg-catalog-conn` | Connection string Catalog |
| `pg-orders-conn` | Connection string Orders |
| `pg-inventory-conn` | Connection string Inventory |
| `azurite-checkpoint` | Blob connection para checkpoints |

> En Portal: Container App → **Containers** → **Edit and deploy** → pestaña **Secrets**.

---

## 10. Paso 8 — Desplegar Catalog

**Objetivo:** Primera API en ACA; valida ACR, secrets y PostgreSQL.

### Enfoque A — Portal Azure

1. **Container Apps** → **Create**
2. **Basics:** name `ca-shopdemo-catalog`, environment `aca-env-shopdemo`
3. **Container:**
   - Image: `acrshopdemolab.azurecr.io/shopdemo-catalog:latest`
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

**Objetivo:** API con ingress **interno** (Orders la consumirá) + Azurite + Event Hubs consumer.

### Enfoque A — Portal Azure

1. Crear Container App `ca-shopdemo-inventory`
2. Imagen: `shopdemo-inventory:latest`
3. **Ingress:** Enabled, **Internal only**, port `8080`
4. Variables:
   - `ConnectionStrings__DefaultConnection` → secret PG Inventory
   - `EventHubs__Enabled` = `true`
   - `EventHubs__ConnectionString` → secret EH
   - `EventHubs__ConsumerGroup` = `inventory-service`
   - `EventHubs__CheckpointStorageConnectionString` → secret Azurite
   - `EventHubs__CheckpointContainerName` = `inventory-checkpoints`

### Enfoque B — Azure CLI

```bash
$PG_INVENTORY_CONN = "Host=$PG_FQDN;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=$PG_PASSWORD;Ssl Mode=Require"
$AZ_CONN = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://${AZ_FQDN}:10000/devstoreaccount1;"

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
  --secrets eh-connection="$EH_CONN" pg-inventory-conn="$PG_INVENTORY_CONN" azurite-checkpoint="$AZ_CONN" \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    ConnectionStrings__DefaultConnection=secretref:pg-inventory-conn \
    EventHubs__Enabled=true \
    EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events \
    EventHubs__ConsumerGroup=inventory-service \
    EventHubs__CheckpointStorageConnectionString=secretref:azurite-checkpoint \
    EventHubs__CheckpointContainerName=inventory-checkpoints

$INVENTORY_URL = az containerapp show --name ca-shopdemo-inventory --resource-group $RG \
  --query properties.configuration.ingress.fqdn -o tsv
echo "Inventory internal: https://$INVENTORY_URL"
```

---

## 12. Paso 10 — Desplegar Orders

**Objetivo:** Conectar a PostgreSQL y a Inventory por URL interna.

### Enfoque A — Portal Azure

1. Container App `ca-shopdemo-orders`, ingress **External**
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

**Objetivo:** Observador de eventos; ingress externo en puerto 8080.

### Enfoque A — Portal Azure

1. Container App `ca-shopdemo-analytics`
2. Ingress External, imagen `shopdemo-analytics:latest`
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
  --secrets eh-connection="$EH_CONN" azurite-checkpoint="$AZ_CONN" \
  --env-vars \
    ASPNETCORE_ENVIRONMENT=Production \
    EventHubs__Enabled=true \
    EventHubs__ConnectionString=secretref:eh-connection \
    EventHubs__EventHubName=shopdemo-events \
    EventHubs__ConsumerGroup=analytics-service \
    EventHubs__CheckpointStorageConnectionString=secretref:azurite-checkpoint \
    EventHubs__CheckpointContainerName=analytics-checkpoints
```

---

## 14. Paso 12 — Probar el flujo

| # | Acción | Cómo |
|---|---|---|
| 1 | Abrir Swagger Catalog | `https://<catalog-fqdn>/swagger` |
| 2 | `POST /api/products` | Crear producto |
| 3 | Analytics | `GET https://<analytics-fqdn>/api/analytics/events` |
| 4 | Orders | Crear y confirmar pedido |
| 5 | Ver logs | Portal → Container App → **Log stream** o Log Analytics |

Usa también [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) sustituyendo `localhost` por los FQDN de ACA.

---

## 15. Paso 13 — GitHub Actions (CI/CD)

**Objetivo:** Automatizar build, push a ACR y actualización de Container Apps.

Archivo de ejemplo: `.github/workflows/deploy-azure.yml`

### Configurar secrets en GitHub

| Secret | Valor |
|---|---|
| `AZURE_CREDENTIALS` | JSON de service principal (`az ad sp create-for-rbac`) |
| `ACR_NAME` | `acrshopdemolab` |
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

El workflow hace: checkout → login → build/push 4 imágenes → `az containerapp update` por servicio.

---

## 16. Paso 14 — Limpieza de recursos

### Portal

1. Resource Group `rg-shopdemo-lab`
2. **Delete resource group** → confirmar nombre

### CLI

```bash
az group delete --name $RG --yes --no-wait
```

---

## 17. Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| `Image pull failed` | ACR sin credenciales en ACA | Revisar registry username/password en la app |
| API no arranca | Puerto incorrecto | Confirmar `target-port 8080` y `ASPNETCORE_URLS` en Dockerfile |
| Orders 502 al confirmar | URL Inventory incorrecta | Verificar `InventoryApi__BaseUrl` con FQDN **interno** |
| Sin eventos en Analytics | EH deshabilitado o consumer group | Revisar `EventHubs__Enabled` y grupo `analytics-service` en Azure |
| EF migration error | PG no accesible | Abrir puerto 5432 en ACI; revisar SSL en connection string |

---

## Referencias

- [TEORIA-CONTENEDORES-AZURE.md](./TEORIA-CONTENEDORES-AZURE.md)
- [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./REQUERIMIENTOS-DESPLIEGUE-AZURE.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
