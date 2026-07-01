# Historias de Usuario — Analytics + .NET Aspire (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](./REQUERIMIENTOS-ANALYTICS-ASPIRE.md) |
| **Personas** | Alumno desarrollador, Instructor, Observador del sistema |

---

## Épica AH — Orquestación con App Host

### HU-AH-01 — Arrancar solución completa desde AppHost

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-AH-01, RF-AH-06 |

**Como** alumno, **quiero** ejecutar un solo proyecto AppHost, **para** levantar Catalog, Orders, Inventory y Analytics sin docker-compose manual.

**Modelo:** Proyecto `ShopDemo.AppHost` (configuración Aspire, **N/A** dominio).

**Criterios de aceptación:**
- [ ] `dotnet run --project Aspire/ShopDemo.AppHost` inicia 4 APIs en puertos 8001–8004.
- [ ] Aspire Dashboard muestra todos los recursos.

---

### HU-AH-02 — Provisionar PostgreSQL multi-base

| **Requerimiento** | RF-AH-02 |

**Como** AppHost, **quiero** crear 3 bases PostgreSQL, **para** aislar datos por bounded context.

**Modelo:** Recurso Aspire PostgreSQL (**N/A** entidad).

**Criterios:** Bases `ShopDemoCatalog`, `ShopDemoOrders`, `ShopDemoInventory` accesibles por connection string inyectada.

---

### HU-AH-03 — Provisionar Azurite para checkpoints

| **Requerimiento** | RF-AH-03 |

**Como** consumidor Event Hubs, **quiero** Azurite local, **para** persistir checkpoints sin Azure Storage real.

**Criterios:** Contenedores `inventory-checkpoints` y `analytics-checkpoints` configurables.

---

### HU-AH-04 — Inyectar Event Hubs a los 4 servicios

| **Requerimiento** | RF-AH-04, RF-AH-07 |

**Reglas:** `EventHubs__Enabled=true`; connection string desde AppHost user secrets.

**Modelo:** Variables de entorno (**N/A** DTO).

**Criterios:** Los 4 servicios reciben configuración Event Hubs al arrancar vía AppHost.

---

### HU-AH-05 — Service discovery Orders → Inventory

| **Requerimiento** | RF-AH-05 |

**Como** Orders, **quiero** URL de Inventory resuelta automáticamente, **para** confirmar pedidos sin hardcode localhost.

**Criterios:** `InventoryApi__BaseUrl` inyectada; confirmación de pedido exitosa en Aspire.

---

## Épica SD — Service Defaults

### HU-SD-01 — Health y OpenTelemetry en Analytics

| **Requerimiento** | RF-SD-01, RF-SD-02, RF-SD-03 |

**Como** operador, **quiero** `/health` y `/alive` en Analytics, **para** alinear con prácticas Aspire.

**Modelo:** Extensiones `AddServiceDefaults` / `MapDefaultEndpoints` (**N/A** dominio).

**Criterios:** Solo Analytics usa ServiceDefaults en fase 1; Catalog/Orders/Inventory sin cambios en `Program.cs`.

---

## Épica AN — Microservicio observador

### HU-AN-01 — Consumir Event Hubs (fan-out)

| **Requerimiento** | RF-AN-01, RF-AN-02, RF-AN-03 |

**Como** analista del lab, **quiero** que Analytics lea el mismo hub con consumer group `analytics-service`, **para** demostrar fan-out vs Inventory.

**Reglas:**
- RN-AN-01: Consumer group distinto de `inventory-service`.
- RN-AN-02: Checkpoints en Azurite blob.
- RN-AN-03: Deserializar `IntegrationEventEnvelope` de Shared.

**Modelo:** **DTO** `ObservedEventDto`; servicio `EventBufferService` (memoria); **N/A** agregado de negocio.

**Criterios:**
- [ ] Crear producto en Catalog → evento visible en Analytics.
- [ ] Inventory sigue auto-registrando stock (sin regresión).

---

### HU-AN-02 — Consultar eventos observados

| **Requerimiento** | RF-AN-05, RF-AN-06 |

**Endpoint:** `GET /api/analytics/events?take=50`

**Como** alumno, **quiero** listar últimos eventos en memoria, **para** verificar integración Event Hubs.

**Reglas:** RN-AN-04: ring buffer máx. 100 eventos; `take` entre 1 y 100.

**Modelo:** **DTO** respuesta con `totalBuffered`, `events[]`.

**Criterios:**
- [ ] `GET /api/analytics/health` retorna estado y contador.
- [ ] Analytics **no** modifica otros servicios (read-only).

---

### HU-AN-03 — Swagger y contenedor independiente

| **Requerimiento** | RF-AN-07, RF-AN-08 |

**Criterios:** Swagger Development; docker-compose del servicio sigue funcionando sin AppHost.

---

## Trazabilidad global

| CA requerimientos | Historias |
|---|---|
| CA-01 | HU-AH-01 |
| CA-02 | HU-AH-01 |
| CA-03 | HU-AN-01 |
| CA-04 | HU-AN-01 |
| CA-05 | HU-AH-05 |
| CA-06 | HU-AN-01 |
| CA-07 | HU-SD-01 (no tocar dominio existente) |
| CA-08 | HU-AN-03 |
