# SPEC — Aspire + Analytics

## Objetivo

Cambios en Analytics/AppHost sin modificar Program.cs de Catalog/Orders/Inventory (Fase 1).

## Referencias

- [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](../../../docs/analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md)
- [IMPLEMENTACION-ANALYTICS-ASPIRE.md](../../../docs/analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md)
- [INTEGRACION-ASPIRE.md](../../../docs/INTEGRACION-ASPIRE.md)

## Criterios de aceptación

- [ ] AppHost arranca 4 APIs + PostgreSQL + Azurite
- [ ] `GET /api/analytics/events` lista eventos con Event Hubs activo
