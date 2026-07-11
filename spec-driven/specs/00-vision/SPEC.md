# SPEC — Visión del proyecto y flujo E2E

## Objetivo

Mantener coherencia entre los microservicios ShopDemo y validar el flujo de compra de punta a punta.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| Visión global | [RETO-TECNICO-SHOPDEMO.md](../../../Documentación del Proyecto/RETO-TECNICO-SHOPDEMO.md) |
| Guía estructural | [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación del Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md) |
| Contratos API | [GUIA-ENDPOINTS.md](../../../Documentación del Proyecto/GUIA-ENDPOINTS.md) |
| Arquitectura | [ARQUITECTURA.md](../../../Documentación del Proyecto/ARQUITECTURA.md) |
| Postman E2E | [ShopDemo.postman_collection.json](../../../Documentación del Proyecto/ShopDemo.postman_collection.json) |

**Por módulo:** cada servicio tiene `REQUERIMIENTOS` + `HISTORIAS-USUARIO` (negocio) y `ANEXO-ESPECIFICACION-TECNICA` + `ANEXO-HISTORIAS-TECNICAS` (técnico). Ver README de `Documentación del Proyecto/catalog/`, `Documentación del Proyecto/orders/`, etc.

## Alcance

| Servicio | Puerto | Rol |
|---|---|---|
| Catalog | 8001 | Catálogo |
| Orders | 8002 | Pedidos |
| Inventory | 8003 | Stock |
| Analytics | 8004 | Eventos |
| MCP Gateway | 8005 | Tools IA |

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Flujo E2E: crear producto → stock → pedido → confirmar → consultar inventario

### Técnico (CA-T)

- [ ] `dotnet build Source/ShopDemo.slnx` sin errores
- [ ] Flujo Postman E2E completo
- [ ] Variables Postman actualizadas según entorno (local / Azure / AWS)

## Instrucciones para el agente

1. Leer [RETO-TECNICO-SHOPDEMO.md](../../../Documentación del Proyecto/RETO-TECNICO-SHOPDEMO.md) y [GUIA-ENDPOINTS.md](../../../Documentación del Proyecto/GUIA-ENDPOINTS.md) antes de cambios cross-service.
2. No romper contratos HTTP documentados.
3. Antes de cambios entre servicios, leer [ARQUITECTURA.md](../../../Documentación del Proyecto/ARQUITECTURA.md) §4.
4. Para un módulo concreto, leer su `REQUERIMIENTOS` (negocio) y `ANEXO-ESPECIFICACION-TECNICA`.
5. Responder en español al usuario; código y rules en inglés.
