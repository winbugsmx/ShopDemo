# Historias de Usuario — Pedidos (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente de negocio** | [REQUERIMIENTOS-ORDERS.md](./REQUERIMIENTOS-ORDERS.md) |
| **Especificación técnica** | [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](./ANEXO-ESPECIFICACION-TECNICA-ORDERS.md) |
| **Historias técnicas** | [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](./ANEXO-HISTORIAS-TECNICAS-ORDERS.md) |

> Este documento contiene **solo historias de negocio**. Las tareas de implementación están en el anexo técnico.

---

## HU-ORD-01 — Registrar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01 |

**Como** cliente de la tienda, **quiero** crear un pedido con al menos una línea de producto y dirección de envío, **para** iniciar una compra referenciando productos del catálogo.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-01 | El pedido debe tener **al menos una línea** |
| RN-02 | Todas las líneas usan la **misma moneda** |
| RN-03 | El total es la **suma de los importes de cada línea** |
| RN-07 | Cantidad **mayor a cero** en cada línea |
| RN-08 | Cada línea referencia un producto válido |
| RN-ORD-09 | Estado inicial: **Pendiente** |
| RN-ORD-10 | Se guarda **snapshot** de nombre y precio del producto |

### Criterios de aceptación (CA-N)

- [ ] **CA-N01:** Con datos válidos, el sistema confirma el alta con estado Pendiente e identificador único.
- [ ] **CA-N02:** Sin líneas de producto, el sistema rechaza e informa el motivo.
- [ ] **CA-N11:** Con datos inválidos, el sistema indica qué corregir en lenguaje comprensible.

---

## HU-ORD-02 — Consultar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |

**Como** operador de ventas, **quiero** consultar un pedido por su identificador, **para** ver su estado, líneas, totales y dirección de envío.

### Criterios de aceptación (CA-N)

- [ ] **CA-N03:** Con identificador existente, el operador ve el detalle completo del pedido.
- [ ] **CA-N04:** Con identificador inexistente, el sistema informa que no se encontró.

---

## HU-ORD-03 — Listar pedidos por cliente

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |

**Como** operador de ventas, **quiero** listar los pedidos de un cliente, **para** dar soporte post-venta y seguimiento.

### Criterios de aceptación (CA-N)

- [ ] **CA-N05:** Para un cliente válido, el sistema devuelve la lista de sus pedidos (vacía o con resultados).

---

## HU-ORD-04 — Confirmar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04 |

**Como** operador de ventas, **quiero** confirmar un pedido pendiente, **para** aprobar la compra y reservar stock en inventario.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-06 | Solo pedidos **Pendiente** pueden confirmarse |
| RN-ORD-11 | Antes de confirmar, se **reserva stock** en inventario |
| RN-ORD-12 | Tras confirmar, el estado pasa a **Confirmado** |

### Criterios de aceptación (CA-N)

- [ ] **CA-N06:** Pedido Pendiente con stock suficiente → estado Confirmado e inventario actualizado.
- [ ] **CA-N07:** Pedido ya Confirmado → el sistema rechaza la operación.
- [ ] **CA-N11:** Sin stock suficiente, el sistema informa el motivo sin confirmar el pedido.

---

## HU-ORD-05 — Cancelar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03 |

**Como** cliente de la tienda, **quiero** cancelar mi pedido indicando un motivo, **para** anular la compra y recuperar el stock si ya se había reservado.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-04 | No cancelar en estado **Entregado** |
| RN-05 | No cancelar en estado **Enviado** |
| RN-ORD-13 | Si estaba **Confirmado**, se **libera stock** en inventario |
| RN-ORD-14 | Pedido **Cancelado** no admite más cambios |

### Criterios de aceptación (CA-N)

- [ ] **CA-N08:** Pedido Pendiente → estado Cancelado con motivo registrado.
- [ ] **CA-N09:** Pedido Enviado o Entregado → el sistema rechaza la cancelación.
- [ ] **CA-N10:** Pedido Confirmado cancelado → el stock reservado se libera en inventario.

---

## Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-01 | HU-ORD-01 |
| RF-02 | HU-ORD-02, HU-ORD-03 |
| RF-03 | HU-ORD-05 |
| RF-04 | HU-ORD-04 |
| RF-05–RF-10 | Ver [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](./ANEXO-HISTORIAS-TECNICAS-ORDERS.md) |

Implementación técnica: ver [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](./ANEXO-HISTORIAS-TECNICAS-ORDERS.md).
