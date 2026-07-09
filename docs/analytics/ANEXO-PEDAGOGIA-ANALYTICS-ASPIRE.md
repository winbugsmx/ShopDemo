# Anexo — Pedagogía: Analytics + Aspire (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Usar **.NET Aspire AppHost** para orquestación local.
2. Implementar consumidor **read-only** de Event Hubs.
3. Demostrar **fan-out** con consumer groups independientes.
4. Centralizar configuración sin alterar dominio existente.
5. Aplicar **ServiceDefaults** en servicio nuevo.
6. Exponer API de observación de eventos.

---

## 2. Contexto pedagógico

| Aspecto | Detalle |
|---|---|
| Posición | Etapa 5–6 (tras Event Hubs, antes release nube) |
| Prerequisitos | Catalog, Orders, Inventory + Event Hubs |
| Arquitectura | Observador / CQRS lectura |

---

## 3. Tiempo estimado

| Actividad | Duración |
|---|---|
| AppHost + configuración | 1.5–2 h |
| Analytics.Api consumidor | 2–3 h |
| Validación E2E Aspire | 1 h |
| **Total** | **4–6 h** |

---

## 4. Entregables

| # | Entregable |
|---|---|
| 1 | `dotnet run --project Aspire/ShopDemo.AppHost` funcional |
| 2 | Captura Aspire Dashboard con 4 APIs |
| 3 | `GET /api/analytics/events` con evento ProductCreated |
| 4 | Evidencia inventario sin regresión |
| 5 | Código en `Aspire/ShopDemo.Analytics.Api` |

---

## 5. Reflexión guiada

1. ¿Por qué Analytics usa consumer group distinto de Inventory?
2. ¿Qué ventaja tiene AppHost frente a docker-compose manual?
3. ¿Por qué no se modifica el dominio de Catalog en fase 1?

---

## 6. Referencias

- [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md)
- [INTEGRACION-ASPIRE.md](../INTEGRACION-ASPIRE.md)
