# SPEC — Azure Event Hubs

## Objetivo

Configurar o extender mensajería sin commitear secretos.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| Guía principal | [INTEGRACION-AZURE-EVENT-HUBS.md](../../../Documentación del Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md) |
| Código referencia | [ANEXO-CODIGO-EVENT-HUBS.md](../../../Documentación del Proyecto/ANEXO-CODIGO-EVENT-HUBS.md) |
| Negocio Catalog | [REQUERIMIENTOS-CATALOG.md](../../../Documentación del Proyecto/catalog/REQUERIMIENTOS-CATALOG.md) (RF-04, HU-CAT-02) |
| Negocio Inventory | [REQUERIMIENTOS-INVENTORY.md](../../../Documentación del Proyecto/inventory/REQUERIMIENTOS-INVENTORY.md) |
| Técnica Inventory | [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](../../../Documentación del Proyecto/inventory/ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md) |
| Técnica Analytics | [ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md](../../../Documentación del Proyecto/analytics/ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación del Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

> Event Hubs no tiene módulo `REQUERIMIENTOS` propio; requisitos repartidos entre Catalog, Inventory, Analytics y la guía de integración.

## Alcance (agente)

- Publicadores en Source/Catalog, Source/Orders, Source/Inventory
- Consumidores: `inventory-service`, `analytics-service`
- Secretos en `.env`, user secrets o secretos cloud

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Crear producto en Catalog puede reflejarse en Inventory (auto-stock) y Analytics

### Técnico (CA-T)

- [ ] Connection strings solo en `.env`, user secrets o secretos cloud
- [ ] Consumer group Inventory: `inventory-service`
- [ ] Consumer group Analytics: `analytics-service`
- [ ] Nada sensible en git

## Instrucciones para el agente

1. Leer [INTEGRACION-AZURE-EVENT-HUBS.md](../../../Documentación del Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md) completo.
2. Consultar anexos técnicos de Inventory y Analytics para consumers.
3. Nunca commitear connection strings ni claves SAS.
4. Validar flujo crear producto → evento visible en Analytics si aplica.
