# SPEC — Orders (Clean Architecture + CQRS)

## Objetivo

Cambios en pedidos respetando integración HTTP con Inventory y eventos de dominio.

## Referencias

- [REQUERIMIENTOS-ORDERS.md](../../../docs/orders/REQUERIMIENTOS-ORDERS.md)
- [IMPLEMENTACION-ORDERS.md](../../../docs/orders/IMPLEMENTACION-ORDERS.md)
- `Orders/ShopDemo.Orders.Infraestructure/Integrations/InventoryHttpClient.cs`

## Criterios de aceptación

- [ ] Confirmar/cancelar pedido mantiene reserva/liberación en Inventory
- [ ] `InventoryApi__BaseUrl` documentado si cambia configuración

## Instrucciones para el agente

Cualquier cambio en confirmación de pedido debe considerar llamada síncrona a Inventory.
