# Historias de Usuario — Inventario (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente de negocio** | [REQUERIMIENTOS-INVENTORY.md](./REQUERIMIENTOS-INVENTORY.md) |
| **Especificación técnica** | [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](./ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](./ANEXO-HISTORIAS-TECNICAS-INVENTORY.md) |

> Este documento contiene **solo historias de negocio**. Las tareas de implementación están en el anexo técnico.

---

## HU-INV-01 — Registrar stock inicial

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01 |

**Como** operador de inventario, **quiero** registrar stock para un producto del catálogo, **para** que el producto pueda venderse y reservarse en pedidos.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-INV-03 | Identificador de producto válido |
| RN-INV-04 | Stock inicial ≥ 0 |
| RN-INV-05 | Un solo registro de stock por producto |
| RN-INV-06 | Se guarda snapshot del nombre del producto |

### Criterios de aceptación (CA-N)

- [ ] **CA-N01:** Con datos válidos, el stock queda registrado y consultable.
- [ ] **CA-N02:** Segundo registro del mismo producto → conflicto o reabastecimiento según operación.
- [ ] **CA-N09:** Con datos inválidos, el sistema indica qué corregir.

---

## HU-INV-02 — Consultar stock disponible

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |

**Como** operador de inventario, **quiero** consultar las unidades disponibles de un producto, **para** validar si hay suficiente stock para ventas o pedidos.

### Criterios de aceptación (CA-N)

- [ ] **CA-N03:** Producto con stock registrado → se muestran las unidades disponibles.
- [ ] **CA-N04:** Producto sin stock registrado → el sistema informa que no se encontró.

---

## HU-INV-03 — Reservar stock al confirmar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03 |

**Como** operador de ventas, **quiero** que al confirmar un pedido se reserven las unidades necesarias en inventario, **para** evitar vender más de lo disponible.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-INV-01 | No reservar más unidades de las disponibles |
| RN-INV-07 | Si el disponible llega a cero, el producto queda agotado |
| RN-INV-08 | La reserva se asocia al identificador del pedido |

### Criterios de aceptación (CA-N)

- [ ] **CA-N05:** Con stock suficiente, la reserva reduce las unidades disponibles.
- [ ] **CA-N06:** Sin stock suficiente, la operación falla y el disponible no cambia.
- [ ] **CA-N08:** Tras reservar, queda constancia de la notificación de cambio.

---

## HU-INV-04 — Liberar stock al cancelar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04 |

**Como** operador de ventas, **quiero** que al cancelar un pedido confirmado se liberen las unidades reservadas, **para** recuperar inventario disponible para otras ventas.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-INV-02 | Las unidades liberadas vuelven al disponible |

### Criterios de aceptación (CA-N)

- [ ] **CA-N07:** Tras cancelar un pedido confirmado, el stock disponible aumenta por las cantidades liberadas.
- [ ] **CA-N08:** Tras liberar, queda constancia de la notificación de cambio.

---

## Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-01 | HU-INV-01 |
| RF-02 | HU-INV-02 |
| RF-03 | HU-INV-03 |
| RF-04 | HU-INV-04 |
| RF-05–RF-08 | Ver [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](./ANEXO-HISTORIAS-TECNICAS-INVENTORY.md) |

Implementación técnica: ver [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](./ANEXO-HISTORIAS-TECNICAS-INVENTORY.md).
