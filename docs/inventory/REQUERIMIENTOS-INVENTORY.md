# Documento de Requerimientos — Inventario (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Inventory — gestión de stock por producto |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Junio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-INVENTORY.md](./HISTORIAS-USUARIO-INVENTORY.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](./ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](./ANEXO-HISTORIAS-TECNICAS-INVENTORY.md) |
| Pedagogía (curso) | [ANEXO-PEDAGOGIA-INVENTORY.md](./ANEXO-PEDAGOGIA-INVENTORY.md) |

---

## Resumen en lenguaje llano

El módulo **Inventario** controla **cuántas unidades hay disponibles** de cada producto registrado en el catálogo. Un **operador de inventario** puede registrar stock inicial y consultar disponibilidad en cualquier momento.

Cuando un **operador de ventas** confirma un pedido, el inventario **reserva** las unidades necesarias para evitar sobreventa. Si el pedido se cancela después de confirmarse, las unidades **vuelven a estar disponibles**.

Cada producto del catálogo tiene como máximo un registro de stock, identificado por el mismo identificador de producto.

---

## 1. Propósito

Definir **qué debe hacer** el módulo de inventario en ShopDemo desde la perspectiva del negocio: registro de stock, consulta de disponibilidad, reserva al confirmar pedidos y liberación al cancelarlos.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Operador de inventario** | Registra stock inicial y consulta disponibilidad |
| **Operador de ventas** | Dispara reserva y liberación al confirmar o cancelar pedidos |
| **Administrador de inventario** | Supervisa reglas y niveles de stock |
| **Sistema de pedidos** | Solicita reserva y liberación de unidades |

---

## 3. Contexto de negocio

Flujo integrado de la tienda (visión de negocio):

| Paso | Qué ocurre |
|---|---|
| 1 | El catálogo registra un **producto** con su identificador |
| 2 | El operador de inventario **registra stock** para ese producto |
| 3 | Un **cliente crea un pedido** que incluye ese producto |
| 4 | Al **confirmar el pedido**, se **reservan unidades** en inventario |
| 5 | Se puede **consultar** cuántas unidades quedan disponibles |
| 6 | Al **cancelar un pedido confirmado**, se **liberan** las unidades reservadas |

---

## 4. Alcance

### 4.1 Incluido (MVP)

| ID | Requerimiento de negocio |
|---|---|
| RF-01 | Registrar stock inicial para un producto del catálogo |
| RF-02 | Consultar unidades disponibles por producto |
| RF-03 | Reservar unidades al confirmar un pedido |
| RF-04 | Liberar unidades al cancelar un pedido confirmado |
| RF-05 | Conservar el inventario de forma permanente entre sesiones |
| RF-06 | Notificar a otros procesos cuando el stock cambia |
| RF-07 | Permitir explorar las operaciones disponibles (documentación de la API) |
| RF-08 | Operar en un entorno de prueba reproducible para el equipo |

### 4.2 Fuera de alcance

- Multi-almacén, reservas parciales y reglas de reabastecimiento avanzadas
- Outbox Pattern y garantías exactly-once entre sistemas
- Sincronización automática catálogo → inventario (se registra stock manualmente tras crear producto)

> Event Hubs, Aspire AppHost y despliegue en Kubernetes/nube se cubren en las **etapas 5–11**.

---

## 5. Lenguaje ubicuo

| Término | Significado para el negocio | Evitar |
|---|---|---|
| **Registro de stock** | Cantidad de unidades disponibles de un producto | “Entrada de inventario” sin definición |
| **Producto** | Artículo del catálogo, referenciado por identificador | Referencia directa al agregado de Catalog |
| **Unidades disponibles** | Cantidad que puede venderse o reservarse | “Stock” ambiguo sin contexto |
| **Reservar** | Apartar unidades al confirmar un pedido | “Descontar” sin contexto de pedido |
| **Liberar** | Devolver unidades al cancelar un pedido confirmado | “Reponer” sin motivo |
| **Reabastecer** | Aumentar unidades disponibles | “Agregar stock” sin reglas |
| **Agotado** | Cero unidades disponibles | “Sin stock” sin evento |

---

## 6. Reglas de negocio

| ID | Regla |
|---|---|
| RN-INV-01 | No se puede reservar más unidades de las **disponibles** |
| RN-INV-02 | Al liberar, las unidades **vuelven a estar disponibles** por la cantidad indicada |
| RN-INV-03 | El identificador de producto no puede estar vacío |
| RN-INV-04 | El stock inicial no puede ser **negativo** |
| RN-INV-05 | Un producto solo tiene **un registro de stock** (identificador único) |
| RN-INV-06 | Al registrar stock por primera vez, se guarda **snapshot del nombre** del producto |
| RN-INV-07 | Cuando las unidades disponibles llegan a **cero**, el producto queda agotado |
| RN-INV-08 | La reserva se asocia al **identificador del pedido** que la originó |

---

## 7. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N01 | Dado un producto del catálogo con cantidad válida, cuando el operador registra stock, entonces el producto queda disponible para consulta y venta |
| CA-N02 | Dado un producto con stock ya registrado, cuando se intenta registrar de nuevo el mismo producto, entonces el sistema informa el conflicto o aplica reabastecimiento según la operación |
| CA-N03 | Dado un producto con stock registrado, cuando el operador consulta disponibilidad, entonces ve las unidades disponibles |
| CA-N04 | Dado un producto sin stock registrado, cuando se consulta, entonces el sistema informa que no se encontró |
| CA-N05 | Dado stock suficiente, cuando se confirma un pedido, entonces las unidades se reservan y el disponible disminuye |
| CA-N06 | Dado stock insuficiente, cuando se intenta confirmar un pedido, entonces la confirmación falla y el disponible no cambia |
| CA-N07 | Dado un pedido confirmado cancelado, cuando se libera stock, entonces las unidades vuelven al disponible |
| CA-N08 | Dado un cambio relevante de stock, entonces queda constancia de la notificación |
| CA-N09 | Dado un error de regla de negocio, cuando ocurre una operación inválida, entonces el usuario recibe un mensaje claro |

---

## 8. Trazabilidad

| Requerimiento | Historia de usuario |
|---|---|
| RF-01 | [HU-INV-01](./HISTORIAS-USUARIO-INVENTORY.md#hu-inv-01--registrar-stock-inicial) |
| RF-02 | [HU-INV-02](./HISTORIAS-USUARIO-INVENTORY.md#hu-inv-02--consultar-stock-disponible) |
| RF-03 | [HU-INV-03](./HISTORIAS-USUARIO-INVENTORY.md#hu-inv-03--reservar-stock-al-confirmar-pedido) |
| RF-04 | [HU-INV-04](./HISTORIAS-USUARIO-INVENTORY.md#hu-inv-04--liberar-stock-al-cancelar-pedido) |
| RF-05–RF-08 | Implementación en [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](./ANEXO-HISTORIAS-TECNICAS-INVENTORY.md) |

---

## 9. Referencias

- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../GUIA-ESTRUCTURA-DOCUMENTACION.md)
- [REQUERIMIENTOS-CATALOG.md](../catalog/REQUERIMIENTOS-CATALOG.md)
- [REQUERIMIENTOS-ORDERS.md](../orders/REQUERIMIENTOS-ORDERS.md)
- [RETO-TECNICO-SHOPDEMO.md](../RETO-TECNICO-SHOPDEMO.md)
