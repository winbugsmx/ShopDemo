# Documento de Requerimientos — Pedidos (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Módulo** | Orders — gestión del ciclo de vida de pedidos |
| **Versión** | 2.0 (enfoque negocio) |
| **Fecha** | Junio 2026 |

**Documentos relacionados:**

| Capa | Documento |
|---|---|
| Historias de usuario | [HISTORIAS-USUARIO-ORDERS.md](./HISTORIAS-USUARIO-ORDERS.md) |
| Especificación técnica | [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](./ANEXO-ESPECIFICACION-TECNICA-ORDERS.md) |
| Historias técnicas | [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](./ANEXO-HISTORIAS-TECNICAS-ORDERS.md) |
| Pedagogía (curso) | [ANEXO-PEDAGOGIA-ORDERS.md](./ANEXO-PEDAGOGIA-ORDERS.md) |

---

## Resumen en lenguaje llano

El módulo **Pedidos** permite que un **cliente** de la tienda **inicie una compra** indicando qué productos quiere, en qué cantidad y a qué dirección debe enviarse. Cada pedido recibe un identificador único y pasa por estados claros: pendiente, confirmado, enviado, entregado o cancelado.

Un **operador de ventas** puede consultar pedidos, confirmarlos (lo que reserva stock en inventario) o dar seguimiento post-venta. El **cliente** puede cancelar su pedido mientras aún no haya sido enviado.

El sistema guarda una **copia del nombre y precio** de cada producto al momento del pedido, para que cambios futuros en el catálogo no alteren pedidos ya registrados.

---

## 1. Propósito

Definir **qué debe hacer** el módulo de pedidos en ShopDemo desde la perspectiva del negocio: registro de compras, consulta, confirmación con reserva de stock, cancelación y reglas del ciclo de vida del pedido.

---

## 2. Actores

| Actor | Rol |
|---|---|
| **Cliente de la tienda** | Crea pedidos y puede cancelarlos |
| **Operador de ventas** | Consulta pedidos, confirma pedidos y da soporte post-venta |
| **Administrador de pedidos** | Supervisa el flujo y las reglas del módulo |
| **Sistema de inventario** | Recibe solicitudes de reserva y liberación de stock al confirmar o cancelar |

---

## 3. Contexto de negocio

Flujo integrado de la tienda (visión de negocio):

| Paso | Qué ocurre |
|---|---|
| 1 | El catálogo registra un **producto** con su identificador |
| 2 | Inventario asigna **stock** a ese producto |
| 3 | El **cliente crea un pedido** con líneas que referencian productos del catálogo |
| 4 | El **operador confirma el pedido** y se **reserva stock** en inventario |
| 5 | El pedido puede **enviarse**, **entregarse** o **cancelarse** según las reglas |
| 6 | El **operador consulta** el estado y el detalle de cualquier pedido |

---

## 4. Alcance

### 4.1 Incluido (MVP)

| ID | Requerimiento de negocio |
|---|---|
| RF-01 | Registrar un pedido con al menos una línea de producto y dirección de envío |
| RF-02 | Consultar un pedido por su identificador y listar pedidos de un cliente |
| RF-03 | Cancelar un pedido con motivo, respetando los estados permitidos |
| RF-04 | Confirmar un pedido pendiente, reservando stock en inventario |
| RF-05 | Conservar el historial de pedidos de forma permanente |
| RF-06 | Notificar a otros procesos cuando un pedido se crea, confirma o cancela |
| RF-07 | Rechazar operaciones inválidas con mensajes comprensibles |
| RF-08 | Permitir explorar las operaciones disponibles (documentación de la API) |
| RF-09 | Operar en un entorno de prueba reproducible para el equipo |
| RF-10 | Aplicar cambios de estructura de datos al iniciar en desarrollo |

### 4.2 Fuera de alcance

- Pagos, envíos físicos y notificaciones al cliente
- Validación síncrona de existencia de producto en catálogo (se usa identificador y snapshot)
- Outbox Pattern y garantías exactly-once entre sistemas
- Transiciones de envío y entrega expuestas al usuario en el MVP (estados preparados en reglas)

> Event Hubs, Aspire AppHost y despliegue en Kubernetes/nube se cubren en las **etapas 5–11**.

---

## 5. Lenguaje ubicuo

| Término | Significado para el negocio | Evitar |
|---|---|---|
| **Pedido** | Compra del cliente con una o más líneas de producto | “Orden”, “Venta” |
| **Línea de pedido** | Producto, cantidad y precio al momento de la compra | “Item del carrito” |
| **Cliente** | Persona o cuenta que realiza el pedido | “Usuario” genérico |
| **Registrar pedido** | Iniciar una nueva compra | “Crear orden” |
| **Estado del pedido** | Fase del ciclo de vida (pendiente, confirmado, etc.) | “Código de estado” |
| **Total del pedido** | Suma de los importes de todas las líneas | Solo un número sin moneda |
| **Dirección de envío** | Lugar donde debe entregarse el pedido | “Dirección” sin contexto |
| **Snapshot de precio** | Precio y nombre guardados al registrar el pedido | Referencia viva al catálogo |
| **Confirmar pedido** | Aprobar un pedido pendiente y reservar stock | “Aprobar” sin reserva |
| **Cancelar pedido** | Anular el pedido y liberar stock si ya se reservó | “Eliminar” (borrado físico) |

---

## 6. Ciclo de vida del pedido (máquina de estados)

Estados posibles y transiciones en lenguaje de negocio:

| Estado | Significado |
|---|---|
| **Pendiente** | Pedido registrado; aún no confirmado ni reservado en inventario |
| **Confirmado** | Pedido aprobado; stock reservado en inventario |
| **Enviado** | Pedido despachado al cliente |
| **Entregado** | Pedido recibido por el cliente; ciclo cerrado |
| **Cancelado** | Pedido anulado; no admite más cambios |

### Transiciones permitidas

| Desde | Acción de negocio | Hacia |
|---|---|---|
| — | Registrar pedido | Pendiente |
| Pendiente | Confirmar pedido | Confirmado |
| Pendiente | Cancelar pedido | Cancelado |
| Confirmado | Cancelar pedido | Cancelado |
| Confirmado | Marcar como enviado | Enviado |
| Enviado | Marcar como entregado | Entregado |

### Transiciones prohibidas

| Desde | Acción | Motivo de negocio |
|---|---|---|
| Enviado | Cancelar | El pedido ya salió del almacén |
| Entregado | Cancelar | El pedido ya fue recibido por el cliente |
| Cancelado | Cualquier modificación | El pedido está cerrado |

---

## 7. Reglas de negocio

| ID | Regla |
|---|---|
| RN-01 | Un pedido debe tener **al menos una línea** de producto |
| RN-02 | Todas las líneas del pedido deben usar la **misma moneda** |
| RN-03 | El total del pedido es la **suma de los importes de cada línea** |
| RN-04 | No se puede cancelar un pedido en estado **Entregado** |
| RN-05 | No se puede cancelar un pedido en estado **Enviado** |
| RN-06 | Solo pedidos en estado **Pendiente** pueden confirmarse |
| RN-07 | La cantidad en cada línea debe ser **mayor a cero** |
| RN-08 | Cada línea debe referenciar un producto válido (identificador no vacío) |
| RN-ORD-09 | Al registrar un pedido, el estado inicial es **Pendiente** |
| RN-ORD-10 | Se guarda **snapshot** del nombre y precio del producto; no se depende del catálogo en tiempo real |
| RN-ORD-11 | Antes de confirmar, debe **reservarse stock** en inventario por cada línea |
| RN-ORD-12 | Tras confirmar correctamente, el estado pasa a **Confirmado** |
| RN-ORD-13 | Si el pedido estaba **Confirmado**, al cancelar se **libera el stock** reservado |
| RN-ORD-14 | Un pedido **Cancelado** no admite más cambios de estado ni de contenido |

---

## 8. Criterios de aceptación de negocio (CA-N)

| ID | Criterio |
|---|---|
| CA-N01 | Dado un pedido con al menos una línea y dirección válida, cuando el cliente lo registra, entonces el sistema confirma el alta con estado Pendiente y un identificador único |
| CA-N02 | Dado un pedido sin líneas, cuando se intenta registrar, entonces el sistema rechaza la operación e informa el motivo |
| CA-N03 | Dado un pedido existente, cuando el operador lo consulta por identificador, entonces ve estado, líneas, totales y dirección de envío |
| CA-N04 | Dado un identificador de pedido inexistente, cuando se consulta, entonces el sistema informa que no se encontró |
| CA-N05 | Dado un cliente con pedidos previos, cuando el operador lista por cliente, entonces obtiene la lista correspondiente (vacía o con pedidos) |
| CA-N06 | Dado un pedido en estado Pendiente con stock suficiente, cuando el operador lo confirma, entonces el estado pasa a Confirmado y el inventario refleja la reserva |
| CA-N07 | Dado un pedido ya Confirmado, cuando se intenta confirmar de nuevo, entonces el sistema rechaza la operación |
| CA-N08 | Dado un pedido Pendiente, cuando el cliente lo cancela con motivo, entonces el estado pasa a Cancelado |
| CA-N09 | Dado un pedido Enviado o Entregado, cuando se intenta cancelar, entonces el sistema rechaza la operación |
| CA-N10 | Dado un pedido Confirmado, cuando el cliente lo cancela, entonces el stock reservado se libera en inventario |
| CA-N11 | Dado un error de regla de negocio, cuando ocurre una operación inválida, entonces el usuario recibe un mensaje claro (no un error técnico crudo) |

---

## 9. Trazabilidad

| Requerimiento | Historia de usuario |
|---|---|
| RF-01 | [HU-ORD-01](./HISTORIAS-USUARIO-ORDERS.md#hu-ord-01--registrar-pedido) |
| RF-02 | [HU-ORD-02](./HISTORIAS-USUARIO-ORDERS.md#hu-ord-02--consultar-pedido), [HU-ORD-03](./HISTORIAS-USUARIO-ORDERS.md#hu-ord-03--listar-pedidos-por-cliente) |
| RF-03 | [HU-ORD-05](./HISTORIAS-USUARIO-ORDERS.md#hu-ord-05--cancelar-pedido) |
| RF-04 | [HU-ORD-04](./HISTORIAS-USUARIO-ORDERS.md#hu-ord-04--confirmar-pedido) |
| RF-05–RF-10 | Implementación en [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](./ANEXO-HISTORIAS-TECNICAS-ORDERS.md) |

---

## 10. Referencias

- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../GUIA-ESTRUCTURA-DOCUMENTACION.md)
- [REQUERIMIENTOS-CATALOG.md](../catalog/REQUERIMIENTOS-CATALOG.md)
- [REQUERIMIENTOS-INVENTORY.md](../inventory/REQUERIMIENTOS-INVENTORY.md)
- [RETO-TECNICO-SHOPDEMO.md](../RETO-TECNICO-SHOPDEMO.md)
