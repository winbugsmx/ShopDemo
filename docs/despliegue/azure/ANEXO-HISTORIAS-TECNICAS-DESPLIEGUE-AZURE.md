# Anexo — Historias técnicas: Despliegue Azure (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Historias de negocio** | [HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md](./HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md) |
| **Especificación** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md) |
| **Capa** | B — Tareas de implementación |

> Historias orientadas al **alumno / equipo de desarrollo**. No son necesidades de usuario final.

---

## HT-AZ-01 — Publicar imágenes en ACR

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-01 |
| **Objetivo técnico** | Imágenes en registro central |

**Como** desarrollador, **quiero** construir y subir las 5 imágenes Docker a ACR, **para** que Container Apps las ejecuten.

### Tareas

| # | Tarea |
|---|---|
| 1 | `az acr login --name <acr>` |
| 2 | Build desde raíz: `docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t <acr>.azurecr.io/shopdemo-catalog:latest .` |
| 3 | Repetir para orders, inventory, analytics, MCP |
| 4 | `docker push` de cada tag |

### Criterios (CA-T)

- [ ] **CA-T-AZ-02:** 5 repos/tags en ACR.
- [ ] Login ACR exitoso sin credenciales en git.

---

## HT-AZ-02 — Crear infraestructura base Azure

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-01 |

**Como** desarrollador, **quiero** Resource Group, ACR, Log Analytics y Container Apps Environment, **para** alojar las aplicaciones.

### Tareas

| # | Tarea |
|---|---|
| 1 | Crear Resource Group |
| 2 | Crear ACR (Basic) |
| 3 | Crear Log Analytics Workspace |
| 4 | Crear Container Apps Environment vinculado a Log Analytics |

### Criterios (CA-T)

- [ ] Recursos visibles en Portal y vía `az resource list`.

---

## HT-AZ-03 — Desplegar PostgreSQL en ACI

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-02 |

**Como** desarrollador, **quiero** PostgreSQL en ACI con 3 bases, **para** persistencia de lab sin Azure Database gestionado.

### Tareas

| # | Tarea |
|---|---|
| 1 | Desplegar contenedor `postgres:16` en ACI |
| 2 | Crear bases `ShopDemoCatalog`, `ShopDemoOrders`, `ShopDemoInventory` |
| 3 | Registrar connection strings como secretos ACA |

### Criterios (CA-T)

- [ ] APIs arrancan sin error de conexión a base de datos.

---

## HT-AZ-04 — Configurar 5 Container Apps

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-01, HU-AZ-02, HU-AZ-03 |

**Como** desarrollador, **quiero** desplegar Catalog, Orders, Inventory, Analytics y MCP en ACA, **para** exponer el release serverless.

### Tareas

| # | Tarea |
|---|---|
| 1 | Crear Container App por servicio con imagen ACR |
| 2 | Configurar ingress externo (excepto Inventory interno) |
| 3 | Inyectar secretos Event Hubs, PG, Storage checkpoints |
| 4 | Configurar `InventoryApi__BaseUrl` en Orders |

### Criterios (CA-T)

- [ ] **CA-T-AZ-01:** 5 apps Running.
- [ ] **CA-T-AZ-03:** Health Catalog responde.
- [ ] **CA-T-AZ-05:** Confirmación pedido exitosa.

---

## HT-AZ-05 — Configurar Storage Account para checkpoints

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-03 |

**Como** desarrollador, **quiero** Storage Account para checkpoints de Event Hubs, **para** que Inventory y Analytics consuman sin Azurite.

### Criterios (CA-T)

- [ ] **CA-T-AZ-04:** Consumer groups operativos; eventos visibles en Analytics.

---

## HT-AZ-06 — Pipeline GitHub Actions

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-05 |

**Como** desarrollador, **quiero** workflow `deploy-azure.yml` funcional, **para** automatizar build, push y deploy.

### Criterios (CA-T)

- [ ] **CA-T-AZ-07:** Workflow actualiza imagen y revisión ACA.

---

## HT-AZ-07 — Documentar Portal y CLI

| Campo | Detalle |
|---|---|
| **Historia de negocio relacionada** | HU-AZ-05 |

**Como** alumno, **quiero** completar al menos un paso equivalente en Portal y CLI, **para** dominar ambas interfaces.

### Referencias

- [GUIA-RELEASE-PORTAL-AZURE.md](./GUIA-RELEASE-PORTAL-AZURE.md)
- [GUIA-RELEASE-CLI-AZURE.md](./GUIA-RELEASE-CLI-AZURE.md)
- [GUIA-RELEASE-SCRIPT-AZURE.md](./GUIA-RELEASE-SCRIPT-AZURE.md)

---

## Trazabilidad

| Historia negocio | Historias técnicas |
|---|---|
| HU-AZ-01 | HT-AZ-01, HT-AZ-02, HT-AZ-04 |
| HU-AZ-02 | HT-AZ-03, HT-AZ-04 |
| HU-AZ-03 | HT-AZ-05 |
| HU-AZ-05 | HT-AZ-06, HT-AZ-07 |
