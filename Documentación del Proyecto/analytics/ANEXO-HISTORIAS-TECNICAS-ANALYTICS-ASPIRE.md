# Anexo — Historias técnicas: Analytics + Aspire (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-AH-01 — Crear ShopDemo.AppHost

| **HU** | HU-AH-01 |

**Como** alumno, **quiero** proyecto AppHost referenciando 4 APIs, **para** orquestación Aspire.

### Criterios (CA-T)

- [ ] **CA-T-AN-02**

---

## HT-AH-02 — Provisionar PostgreSQL y Azurite

| **HU** | HU-AH-01 |

**Como** alumno, **quiero** recursos Aspire para PG y Azurite, **para** datos y checkpoints locales.

---

## HT-AH-03 — Inyectar Event Hubs y service discovery

| **HU** | HU-AH-01 |

**Como** alumno, **quiero** variables `EventHubs__*` e `InventoryApi__BaseUrl`, **para** mensajería y HTTP Orders→Inventory.

```bash
dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<CS>" \
  --project Source/Aspire/ShopDemo.AppHost
```

---

## HT-AN-01 — Implementar consumidor Event Hubs

| **HU** | HU-AN-01 |

**Como** alumno, **quiero** `EventHubConsumerService` con grupo `analytics-service`, **para** fan-out.

### Modelo

| Artefacto | Tipo |
|---|---|
| `IntegrationEventEnvelope` | DTO Shared |
| `EventBufferService` | Ring buffer memoria |
| `ObservedEventDto` | DTO respuesta API |

### Criterios (CA-T)

- [ ] **CA-T-AN-03, CA-T-AN-04**

---

## HT-AN-02 — Exponer API de consulta

| **HU** | HU-AN-02 |

**Como** alumno, **quiero** `AnalyticsController` con `GET /api/analytics/events`, **para** panel consultable.

---

## HT-SD-01 — Aplicar ServiceDefaults en Analytics

**Como** alumno, **quiero** `AddServiceDefaults()` solo en Analytics, **para** health y OTel sin tocar otras APIs.

### Criterios (CA-T)

- [ ] **CA-T-AN-01:** Source/Catalog, Source/Orders, Source/Inventory Domain sin cambios.

---

## HT-AN-03 — Containerizar Analytics

**Como** alumno, **quiero** Dockerfile Analytics, **para** despliegue cloud etapa 7+.

### Criterios (CA-T)

- [ ] **CA-T-AN-05**

---

## Trazabilidad

| HU negocio | HT |
|---|---|
| HU-AH-01 | HT-AH-01, HT-AH-02, HT-AH-03 |
| HU-AN-01 | HT-AN-01, HT-SD-01 |
| HU-AN-02 | HT-AN-02 |
| — | HT-AN-03 |
