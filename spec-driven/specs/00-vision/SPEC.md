# SPEC — Visión del proyecto y flujo E2E

## Objetivo

Mantener coherencia entre los microservicios ShopDemo y validar el flujo de compra de punta a punta.

## Referencias

- [docs/GUIA-ENDPOINTS.md](../../../docs/GUIA-ENDPOINTS.md)
- [docs/ARQUITECTURA.md](../../../docs/ARQUITECTURA.md)
- [docs/ShopDemo.postman_collection.json](../../../docs/ShopDemo.postman_collection.json)

## Alcance

| Servicio | Puerto | Rol |
|---|---|---|
| Catalog | 8001 | Catálogo |
| Orders | 8002 | Pedidos |
| Inventory | 8003 | Stock |
| Analytics | 8004 | Eventos |
| MCP Gateway | 8005 | Tools IA |

## Criterios de aceptación

- [ ] `dotnet build ShopDemo.slnx` sin errores
- [ ] Flujo Postman E2E: crear producto → stock → pedido → confirmar
- [ ] Variables Postman actualizadas según entorno (local / Azure / AWS)

## Instrucciones para el agente

1. No romper contratos HTTP documentados en GUIA-ENDPOINTS.
2. Antes de cambios cross-service, leer ARQUITECTURA §4.
3. Responder en español al usuario; código y rules en inglés.
