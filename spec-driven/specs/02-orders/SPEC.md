# SPEC — Orders (Clean Architecture + CQRS)

## Objetivo

Cambios en pedidos respetando integración con Inventory y eventos de dominio.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-ORDERS.md](../../../docs/orders/REQUERIMIENTOS-ORDERS.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-ORDERS.md](../../../docs/orders/HISTORIAS-USUARIO-ORDERS.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](../../../docs/orders/ANEXO-ESPECIFICACION-TECNICA-ORDERS.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](../../../docs/orders/ANEXO-HISTORIAS-TECNICAS-ORDERS.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-ORDERS.md](../../../docs/orders/ANEXO-PEDAGOGIA-ORDERS.md) |
| Implementación | [IMPLEMENTACION-ORDERS.md](../../../docs/orders/IMPLEMENTACION-ORDERS.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Ciclo de vida del pedido (crear, confirmar, cancelar, consultar)
- Integración HTTP con Inventory (`InventoryHttpClient`)
- Código: `Orders/`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Pedido con líneas válidas queda en estado Pending (CA-N01)
- [ ] Solo pedidos Pending pueden confirmarse (RN-06)
- [ ] Cancelación respeta estados Shipped/Delivered (RN-04, RN-05)

### Técnico (CA-T)

- [ ] Confirmar/cancelar mantiene reserva/liberación en Inventory
- [ ] `InventoryApi__BaseUrl` documentado si cambia configuración
- [ ] Handlers sin lógica de negocio (solo orquestan)

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS** para máquina de estados y reglas RN-*.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA** para endpoints y agregado `Order`.
3. Cualquier cambio en confirmación debe considerar llamada síncrona a Inventory.
4. Validar CA-N y CA-T al finalizar.
