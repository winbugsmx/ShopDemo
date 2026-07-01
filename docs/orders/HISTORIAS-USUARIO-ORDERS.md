# Historias de Usuario — Microservicio Orders (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-ORDERS.md](./REQUERIMIENTOS-ORDERS.md) |
| **Bounded Context** | Orders |

---

## HU-ORD-01 — Registrar pedido (PlaceOrder)

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01 |
| **Endpoint** | `POST /api/orders` |

**Como** cliente de la tienda, **quiero** crear un pedido con al menos una línea y dirección de envío, **para** iniciar una compra referenciando productos de Catalog por `ProductId`.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-01 | El pedido debe tener **al menos una línea** |
| RN-02 | Todas las líneas usan la **misma moneda** |
| RN-03 | El total es la **suma de LineTotal** |
| RN-07 | `Quantity` &gt; 0 en cada línea |
| RN-08 | `ProductId` ≠ `Guid.Empty` |
| RN-ORD-09 | Estado inicial: **Pending** |
| RN-ORD-10 | Se guarda **snapshot** de nombre y precio (no referencia agregado Catalog) |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | **Agregado** `Order` |
| Dominio | **Entidad** `OrderLine` |
| Dominio | **VO** `CustomerId`, `ShippingAddress`, `Money`, `OrderStatus`, `Quantity` |
| Dominio | **Evento** `OrderPlacedDomainEvent` |
| Aplicación | **Comando** `PlaceOrderCommand`, **DTO** `OrderDto` |
| API | Request body con `lines[]` y `shippingAddress` |

### Criterios de aceptación

- [ ] **CA-01:** Payload válido → `201 Created` con `status: Pending`.
- [ ] **CA-02:** Pedido sin líneas → `400 Bad Request`.
- [ ] **CA-03:** Persisten tablas `orders` y `order_lines`.
- [ ] **CA-04:** Se emite `OrderPlacedDomainEvent`.

---

## HU-ORD-02 — Consultar pedido por Id

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |
| **Endpoint** | `GET /api/orders/{id}` |

**Como** operador, **quiero** consultar un pedido por su Id, **para** ver estado, líneas y totales.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Query** `GetOrderByIdQuery`, **DTO** `OrderDto` |
| Dominio | Lectura vía `IOrderRepository` (sin modificar agregado) |

### Criterios de aceptación

- [ ] **CA-05:** Id existente → `200 OK` con `OrderDto`.
- [ ] **CA-06:** Id inexistente → `404 Not Found`.

---

## HU-ORD-03 — Listar pedidos por cliente

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 (extensión) |
| **Endpoint** | `GET /api/orders?customerId={guid}` |

**Como** operador, **quiero** listar pedidos de un cliente, **para** dar soporte post-venta.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Query** `GetOrdersByCustomerQuery`, **DTO** lista |
| Infra | `IOrderRepository.GetByCustomerAsync` |

### Criterios de aceptación

- [ ] **CA-07:** Retorna lista (vacía o con pedidos) para `customerId` válido.

---

## HU-ORD-04 — Confirmar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04 |
| **Endpoint** | `POST /api/orders/{id}/confirm` |

**Como** sistema de ventas, **quiero** confirmar un pedido en estado Pending, **para** reservar stock en Inventory y avanzar el flujo.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-06 | Solo pedidos **Pending** pueden confirmarse |
| RN-ORD-11 | Antes de confirmar, debe reservarse stock en Inventory (HTTP) |
| RN-ORD-12 | Tras confirmar, estado → **Confirmed** |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | `Order.Confirm()` |
| Dominio | **Evento** `OrderConfirmedDomainEvent` |
| Aplicación | **Comando** `ConfirmOrderCommand` |
| Aplicación | **Puerto** `IInventoryService` (HTTP client) |

### Criterios de aceptación

- [ ] **CA-08:** Pending + stock suficiente → `200` y estado Confirmed.
- [ ] **CA-09:** Confirmar pedido ya Confirmed → `400`.
- [ ] **CA-10:** Inventory recibe reserva con `orderId` y líneas.

---

## HU-ORD-05 — Cancelar pedido

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03 |
| **Endpoint** | `POST /api/orders/{id}/cancel` |

**Como** cliente, **quiero** cancelar un pedido con motivo, **para** anular la compra y liberar stock si ya se reservó.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-04 | No cancelar en estado **Delivered** |
| RN-05 | No cancelar en estado **Shipped** |
| RN-ORD-13 | Si estaba **Confirmed**, liberar stock en Inventory |
| RN-ORD-14 | Pedido **Cancelled** no admite más cambios |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | `Order.Cancel(reason)` |
| Dominio | **Evento** `OrderCancelledDomainEvent` |
| Aplicación | **Comando** `CancelOrderCommand` (incluye motivo) |

### Criterios de aceptación

- [ ] **CA-11:** Cancelar Pending → `200`, estado Cancelled.
- [ ] **CA-12:** Cancelar Shipped → `400`.
- [ ] **CA-13:** Cancelar Confirmed libera stock en Inventory.

---

## HU-ORD-06 — Persistir pedidos (EF Core)

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-05 |

**Como** sistema, **quiero** persistir agregados Order en PostgreSQL dedicado, **para** conservar historial de pedidos.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Infra | `OrdersDbContext`, `OrderRepository`, migraciones |
| Dominio | `IOrderRepository` |

### Criterios de aceptación

- [ ] **CA-14:** BD `ShopDemoOrders`, puerto host **5434**.
- [ ] **CA-15:** Relación 1:N Order → OrderLine mapeada correctamente.

---

## HU-ORD-07 — Publicar eventos de dominio

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-06 |

### Modelo requerido

Eventos: `OrderPlaced`, `OrderConfirmed`, `OrderCancelled` (+ `OrderShipped` opcional).

### Criterios de aceptación

- [ ] **CA-16:** Cada transición relevante genera evento publicado vía puerto.

---

## HU-ORD-08 — Validación, Swagger y Docker

| Campo | Detalle |
|---|---|
| **Requerimientos** | RF-07, RF-08, RF-09, RF-10 |

| HU | Entregable | Criterio clave |
|---|---|---|
| Validación | FluentValidation + pipeline | `400` con detalle |
| Swagger | `/swagger` Development | Endpoints documentados |
| Docker | compose API + PG | Puerto **8002** |
| Migraciones | auto en Development | Tablas creadas al arrancar |

---

## Trazabilidad

| RF | Historia |
|---|---|
| RF-01 | HU-ORD-01 |
| RF-02 | HU-ORD-02, HU-ORD-03 |
| RF-03 | HU-ORD-05 |
| RF-04 | HU-ORD-04 |
| RF-05 | HU-ORD-06 |
| RF-06 | HU-ORD-07 |
| RF-07–10 | HU-ORD-08 |
