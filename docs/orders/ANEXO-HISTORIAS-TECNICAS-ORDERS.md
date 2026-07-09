# Anexo — Historias técnicas: Orders (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Historias de negocio** | [HISTORIAS-USUARIO-ORDERS.md](./HISTORIAS-USUARIO-ORDERS.md) |
| **Especificación** | [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](./ANEXO-ESPECIFICACION-TECNICA-ORDERS.md) |
| **Capa** | B — Tareas de implementación |

> Historias orientadas al **equipo de desarrollo**. No son necesidades de usuario final.

---

## Leyenda — Modelo requerido

| Símbolo | Significado |
|---|---|
| **Agregado** | Entidad raíz de dominio |
| **VO** | Value Object |
| **DTO** | Contrato API sin lógica de negocio |
| **Puerto** | Interfaz de infraestructura |

---

## HT-ORD-01 — Modelar agregado Order con ciclo de vida

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01, RF-03, RF-04 |
| **Historia de negocio relacionada** | HU-ORD-01, HU-ORD-04, HU-ORD-05 |

**Como** desarrollador de dominio, **quiero** encapsular el ciclo de vida del pedido en el agregado `Order`, **para** que la lógica no quede en controllers ni handlers.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | **Agregado** `Order` con `PlaceOrder`, `Confirm`, `Cancel` |
| Dominio | **Entidad** `OrderLine` |
| Dominio | **VO** `CustomerId`, `ShippingAddress`, `Money`, `OrderStatus`, `Quantity` |
| Dominio | **Eventos** `OrderPlaced`, `OrderConfirmed`, `OrderCancelled` |

### Criterios (CA-T)

- [ ] **CA-T01:** `PlaceOrder()` es la única forma de crear pedidos.
- [ ] **CA-T02:** `Cancel()` valida estados prohibidos.
- [ ] **CA-T03:** `Confirm()` solo desde `Pending`.
- [ ] **CA-T04:** Eventos de dominio en cada transición relevante.
- [ ] **CA-T05:** VOs invalidan datos en construcción.

---

## HT-ORD-02 — Implementar comandos y consultas CQRS

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01, RF-02, RF-03, RF-04 |
| **Historia de negocio relacionada** | HU-ORD-01 a HU-ORD-05 |

**Como** desarrollador de aplicación, **quiero** separar comandos y consultas con MediatR, **para** orquestar casos de uso sin lógica de negocio en la API.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Comandos** `PlaceOrderCommand`, `ConfirmOrderCommand`, `CancelOrderCommand` |
| Aplicación | **Queries** `GetOrderByIdQuery`, `GetOrdersByCustomerQuery` |
| Aplicación | **DTO** `OrderDto` |
| API | Controllers que delegan a MediatR |

### Criterios (CA-T)

- [ ] **CA-T06:** Handlers solo orquestan; sin lógica de negocio.
- [ ] **CA-T08:** DTOs no exponen el agregado directamente.
- [ ] **CA-T13:** `POST /api/orders` → `201 Created`.
- [ ] **CA-T14:** `GET /api/orders/{id}` → `200` o `404`.

---

## HT-ORD-03 — Persistir pedidos en PostgreSQL

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-05 |

**Como** sistema, **quiero** persistir agregados `Order` en PostgreSQL dedicado, **para** conservar el historial entre reinicios.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Infra | `OrdersDbContext`, `OrderRepository`, migración `InitialCreate` |
| Dominio | `IOrderRepository` con `GetByCustomerAsync`, `GetByStatusAsync` |

### Criterios (CA-T)

- [ ] **CA-T10:** `IOrderRepository` implementado con EF Core.
- [ ] **CA-T11:** Migración inicial generada y aplicada.
- [ ] **CA-T17:** Tablas `orders` y `order_lines` con relación 1:N.

---

## HT-ORD-04 — Publicar eventos de dominio

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-06 |

**Como** sistema, **quiero** publicar eventos de dominio al crear, confirmar o cancelar pedidos, **para** que otros servicios reaccionen de forma asíncrona.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | Puerto `IDomainEventPublisher` |
| Infra | Implementación con logging en desarrollo |

### Criterios (CA-T)

- [ ] **CA-T04:** Cada transición relevante genera evento publicado vía puerto.
- [ ] **CA-T12:** `IDomainEventPublisher` registrado en DI.

---

## HT-ORD-05 — Integrar con Inventory (reserva y liberación)

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04, RF-03 |
| **Historia de negocio relacionada** | HU-ORD-04, HU-ORD-05 |

**Como** sistema, **quiero** invocar Inventory antes de confirmar y al cancelar pedidos confirmados, **para** mantener consistencia de stock.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Puerto** `IInventoryService` (HTTP client) |
| Aplicación | `ConfirmOrderHandler` con reserva previa |
| Aplicación | `CancelOrderHandler` con liberación condicional |

### Criterios (CA-T)

- [ ] **CA-T18:** Confirmar pedido invoca `POST /api/inventory/reservations`.
- [ ] **CA-T19:** Cancelar pedido Confirmado invoca `POST /api/inventory/reservations/release`.

---

## HT-ORD-06 — Validar entrada con FluentValidation

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-07 |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | Validadores para `PlaceOrderCommand`, `CancelOrderCommand` |
| Aplicación | `ValidationBehavior` en pipeline MediatR |
| API | Problem Details vía middleware |

### Criterios (CA-T)

- [ ] **CA-T07:** FluentValidation valida antes del handler.
- [ ] **CA-T09:** Pipeline incluye `ValidationBehavior`.
- [ ] **CA-T15:** Errores de validación → `400` con detalle de campos.

---

## HT-ORD-07 — Documentar API con Swagger

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-08 |

**Como** desarrollador, **quiero** Swagger en Development, **para** probar endpoints sin Postman.

### Criterios (CA-T)

- [ ] Swagger accesible en `/swagger`.
- [ ] Título: **ShopDemo Orders API v1**.

---

## HT-ORD-08 — Ejecutar en Docker Compose

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-09, RF-10 |

### Reglas técnicas

| ID | Regla |
|---|---|
| RN-ORD-15 | Puerto API host: **8002**; PostgreSQL host: **5434** |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `Dockerfile`, `docker-compose.yml` |
| Infra | `DatabaseInitializer` |

### Criterios (CA-T)

- [ ] **CA-T16:** `docker compose up -d --build` levanta API y BD.
- [ ] Migraciones se aplican al iniciar en Development.

---

## HT-ORD-09 — Manejo transversal de errores

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-07 |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `ExceptionHandlingMiddleware` |
| Dominio | `OrderDomainException` |

### Criterios (CA-T)

- [ ] **CA-T15:** Errores de dominio → `400 Bad Request` con `traceId`.

---

## Trazabilidad técnica

| RF | Historia técnica |
|---|---|
| RF-01 | HT-ORD-01, HT-ORD-02 |
| RF-02 | HT-ORD-02 |
| RF-03 | HT-ORD-01, HT-ORD-02, HT-ORD-05 |
| RF-04 | HT-ORD-01, HT-ORD-02, HT-ORD-05 |
| RF-05 | HT-ORD-03 |
| RF-06 | HT-ORD-04 |
| RF-07 | HT-ORD-06, HT-ORD-09 |
| RF-08 | HT-ORD-07 |
| RF-09, RF-10 | HT-ORD-08 |
