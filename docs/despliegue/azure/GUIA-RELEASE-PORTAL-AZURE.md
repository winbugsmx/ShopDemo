# Guía — Release Azure con Portal (visual)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Tiempo estimado** | 8–12 h (manual completo) |
| **Propósito** | Documento para **capturas de pantalla** y clase presencial |

**Ruta rápida:** [GUIA-RELEASE-SCRIPT-AZURE.md](./GUIA-RELEASE-SCRIPT-AZURE.md)  
**Comandos equivalentes:** [GUIA-RELEASE-CLI-AZURE.md](./GUIA-RELEASE-CLI-AZURE.md)

> Sustituye `[📷 Captura: …]` por tus imágenes en `docs/despliegue/azure/imagenes/` (carpeta opcional del instructor).

---

## Nombres a usar en el Portal (no cambiar entre pasos)

| Recurso | Nombre en Portal |
|---|---|
| Resource group | `rg-shopdemo-lab` |
| Región | `East US` (o `mexicocentral`) |
| Event Hubs namespace | `shopdemo-eh-ns-lab01` |
| Event hub | `shopdemo-events` |
| Container registry | `acrshopdemolab01` |
| Storage account | `shopdemochecklab01` |
| Log Analytics | `log-shopdemo` |
| ACA environment | `aca-env-shopdemo` |
| Container Instance PG | `aci-shopdemo-postgres` |
| Container Apps | `ca-shopdemo-catalog`, `ca-shopdemo-inventory`, … |

---

## 0. Acceso al Portal

1. Abrir [https://portal.azure.com](https://portal.azure.com)
2. Iniciar sesión con cuenta del curso
3. Confirmar suscripción correcta (barra superior)

[📷 Captura: Portal Azure con suscripción seleccionada]

**Documentación:** [Azure Portal overview](https://learn.microsoft.com/azure/azure-portal/azure-portal-overview)

---

## 1. Resource Group

**Para qué sirve:** agrupa todos los recursos del lab; al borrarlo se limpia todo.

**Documentación:** [Create resource group](https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)

| Paso | Acción |
|---|---|
| 1 | Buscar **Resource groups** → **Create** |
| 2 | **Subscription:** la del curso |
| 3 | **Resource group name:** `rg-shopdemo-lab` |
| 4 | **Region:** `East US` |
| 5 | **Review + create** → **Create** |

[📷 Captura: formulario Create resource group]

---

## 2. Event Hubs

**Para qué sirve:** bus de mensajería entre Catalog, Orders, Inventory y Analytics.

**Documentación:** [Create Event Hubs namespace](https://learn.microsoft.com/azure/event-hubs/event-hubs-create)

| Paso | Acción |
|---|---|
| 1 | **Create a resource** → **Event Hubs** |
| 2 | **Namespace name:** `shopdemo-eh-ns-lab01` |
| 3 | **Resource group:** `rg-shopdemo-lab` |
| 4 | **Location:** misma región |
| 5 | **Pricing tier:** Basic → **Create** |
| 6 | En el namespace → **Event Hubs** → **+ Event Hub** → Name: `shopdemo-events` |
| 7 | En el hub → **Consumer groups** → crear `inventory-service` y `analytics-service` |
| 8 | Namespace → **Shared access policies** → **RootManageSharedAccessKey** → copiar **Primary Connection String** |

[📷 Captura: Event Hubs namespace creado]  
[📷 Captura: Consumer groups]  
[📷 Captura: Connection string]

---

## 3. Azure Container Registry (ACR)

**Para qué sirve:** almacén privado de imágenes Docker.

**Documentación:** [Create container registry](https://learn.microsoft.com/azure/container-registry/container-registry-get-started-portal)

| Paso | Acción |
|---|---|
| 1 | **Create a resource** → **Container Registry** |
| 2 | **Registry name:** `acrshopdemolab01` |
| 3 | **Resource group:** `rg-shopdemo-lab` |
| 4 | **SKU:** Basic |
| 5 | **Admin user:** Disabled |
| 6 | **Create** |

[📷 Captura: ACR creado — login server `acrshopdemolab01.azurecr.io`]

---

## 4. Storage Account (checkpoints)

**Para qué sirve:** Blob storage para checkpoints de Event Hubs (Inventory y Analytics en ACA).

**Documentación:** [Create storage account](https://learn.microsoft.com/azure/storage/common/storage-account-create)

| Paso | Acción |
|---|---|
| 1 | **Create a resource** → **Storage account** |
| 2 | **Name:** `shopdemochecklab01` |
| 3 | **Resource group:** `rg-shopdemo-lab` |
| 4 | **Performance:** Standard · **Redundancy:** LRS |
| 5 | **Create** |
| 6 | Storage → **Containers** → crear `inventory-checkpoints` y `analytics-checkpoints` |

[📷 Captura: Storage account y contenedores blob]

---

## 5. Log Analytics + Container Apps Environment

**Para qué sirve:** el **Environment** es el plano donde corren las Container Apps; Log Analytics recoge logs.

**Documentación:** [Container Apps environment](https://learn.microsoft.com/azure/container-apps/environment) · [Log Analytics workspace](https://learn.microsoft.com/azure/azure-monitor/logs/quick-create-workspace)

| Paso | Acción |
|---|---|
| 1 | **Create a resource** → **Container Apps Environment** (o desde Container Apps wizard) |
| 2 | **Environment name:** `aca-env-shopdemo` |
| 3 | **Region:** misma que RG |
| 4 | **Logs:** Create new → **Name:** `log-shopdemo` |
| 5 | **Create** |

[📷 Captura: Container Apps Environment con Log Analytics]

---

## 6. PostgreSQL en Container Instances

**Para qué sirve:** base de datos del lab (3 bases en una instancia).

**Documentación:** [Deploy container instance](https://learn.microsoft.com/azure/container-instances/container-instances-quickstart-portal)

| Paso | Acción |
|---|---|
| 1 | **Create a resource** → **Container Instances** |
| 2 | **Name:** `aci-shopdemo-postgres` |
| 3 | **Image:** `postgres:16-alpine` |
| 4 | **Size:** 1 vCPU, 1.5 GiB |
| 5 | **Networking:** Public · DNS label: `shopdemo-pg-lab` · Port `5432` |
| 6 | **Variables:** `POSTGRES_USER=ShopDemo`, `POSTGRES_PASSWORD=<tu-password>` |
| 7 | Tras crear: ejecutar SQL para crear `ShopDemoCatalog`, `ShopDemoOrders`, `ShopDemoInventory` |

[📷 Captura: ACI PostgreSQL — Overview con FQDN]

---

## 7. Container Apps (5 servicios)

**Documentación:** [Deploy Container App](https://learn.microsoft.com/azure/container-apps/quickstart-portal) · [Secrets](https://learn.microsoft.com/azure/container-apps/manage-secrets)

### Orden recomendado

1. `ca-shopdemo-catalog` — Ingress **External**
2. `ca-shopdemo-inventory` — Ingress **Internal**
3. `ca-shopdemo-orders` — External + `InventoryApi__BaseUrl`
4. `ca-shopdemo-analytics` — External
5. `ca-shopdemo-mcp` — External

### Tabla por app (Catalog como ejemplo)

| Pestaña | Valor |
|---|---|
| **Basics** | Name `ca-shopdemo-catalog`, Environment `aca-env-shopdemo` |
| **Container** | Image `acrshopdemolab01.azurecr.io/shopdemo-catalog:latest`, Port `8080` |
| **Ingress** | Enabled, External, Target port `8080` |
| **Secrets** | `eh-connection`, `pg-catalog-conn` |
| **Env vars** | `ConnectionStrings__DefaultConnection` → secret; `EventHubs__*` → ver CLI |

[📷 Captura: Create Container App — Basics]  
[📷 Captura: Ingress External]  
[📷 Captura: Secrets y environment variables]

Detalle de variables por API: [GUIA-RELEASE-CLI-AZURE.md §7](./GUIA-RELEASE-CLI-AZURE.md#7-container-apps-5-servicios).

---

## 8. Publicar imágenes en ACR

**Antes** de que las apps arranquen, sube las 5 imágenes (Docker local o GitHub Actions).

**Documentación:** [Push image to ACR](https://learn.microsoft.com/azure/container-registry/container-registry-get-started-docker-cli)

[📷 Captura: ACR → Repositories con 5 imágenes `shopdemo-*`]

---

## 9. Validación

| Comprobación | Dónde |
|---|---|
| Cada Container App → **Application Url** | Abrir `/swagger` o `/health` |
| Log stream | Container App → **Monitoring** → **Log stream** |

[📷 Captura: FQDN Catalog en Overview]

---

## 10. Limpieza

**Resource groups** → `rg-shopdemo-lab` → **Delete resource group**

[📷 Captura: Delete resource group — confirmación]

---

## Servicios que NO configuras en ACA

| Servicio | Motivo |
|---|---|
| Azurite en ACI | Checkpoints usan **Storage Account** en ACA |
| AKS | Ruta aparte — [GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md) |
