# SPEC — Inventory (Hexagonal)

## Objetivo

Extender casos de uso de stock/reservas manteniendo puertos y adaptadores.

## Referencias

- [REQUERIMIENTOS-INVENTORY.md](../../../docs/inventory/REQUERIMIENTOS-INVENTORY.md)
- [IMPLEMENTACION-INVENTORY.md](../../../docs/inventory/IMPLEMENTACION-INVENTORY.md)
- `Inventory/ShopDemo.Inventory.Api/Adapters/`

## Criterios de aceptación

- [ ] Lógica de dominio en Application/Domain, no en controllers
- [ ] Consumer Event Hubs (`CatalogEventsProcessor`) intacto si no es el scope
