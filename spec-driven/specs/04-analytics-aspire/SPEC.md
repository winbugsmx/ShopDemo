# SPEC — Aspire + Analytics

## Objetivo

Cambios en Analytics/AppHost sin modificar Program.cs de Source/Catalog, Source/Orders, Source/Inventory salvo que el SPEC lo indique.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/ANEXO-PEDAGOGIA-ANALYTICS-ASPIRE.md) |
| Implementación | [IMPLEMENTACION-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) |
| Aspire (guía) | [INTEGRACION-ASPIRE.md](../../../Documentación del Proyecto/INTEGRACION-ASPIRE.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación del Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- AppHost, ServiceDefaults, Analytics API
- Consumer group `analytics-service` en Event Hubs
- Código: `Source/Aspire/`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Operador puede consultar eventos observados del negocio vía Analytics

### Técnico (CA-T)

- [ ] AppHost arranca 4 APIs + PostgreSQL + Azurite
- [ ] `GET /api/analytics/events` lista eventos con Event Hubs activo
- [ ] Consumer group `analytics-service` separado de `inventory-service`

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS** para rol observador de Analytics.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA** para AppHost y checkpoints.
3. No modificar APIs de negocio fuera de alcance.
4. Validar CA-N y CA-T al finalizar.
