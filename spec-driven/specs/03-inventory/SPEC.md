# SPEC — Inventory (Hexagonal)

## Objetivo

Extender casos de uso de stock/reservas manteniendo puertos y adaptadores.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-INVENTORY.md](../../../docs/inventory/REQUERIMIENTOS-INVENTORY.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-INVENTORY.md](../../../docs/inventory/HISTORIAS-USUARIO-INVENTORY.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](../../../docs/inventory/ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](../../../docs/inventory/ANEXO-HISTORIAS-TECNICAS-INVENTORY.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-INVENTORY.md](../../../docs/inventory/ANEXO-PEDAGOGIA-INVENTORY.md) |
| Implementación | [IMPLEMENTACION-INVENTORY.md](../../../docs/inventory/IMPLEMENTACION-INVENTORY.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Stock, reservas, liberaciones
- Consumer Event Hubs (`CatalogEventsProcessor`) si aplica
- Código: `Inventory/ShopDemo.Inventory.Api/Adapters/`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] No reservar más unidades de las disponibles (RN-INV-01)
- [ ] Consulta de stock refleja unidades actuales tras reserva/liberación

### Técnico (CA-T)

- [ ] Lógica de dominio en Application/Domain, no en controllers
- [ ] Consumer Event Hubs intacto si no es el scope del cambio
- [ ] Puertos/adaptadores hexagonales respetados

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS** para reglas de stock y reservas.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA** para puertos y API.
3. No acoplar dominio a EF Core ni HTTP clients directamente.
4. Validar CA-N y CA-T al finalizar.
