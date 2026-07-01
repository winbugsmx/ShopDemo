# Historias de Usuario — Microservicio Inventory (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-INVENTORY.md](./REQUERIMIENTOS-INVENTORY.md) |
| **Arquitectura** | Hexagonal |

---

## HU-INV-01 — Registrar stock inicial

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01 |
| **Endpoint** | `POST /api/inventory/stock` |

**Como** operador de inventario, **quiero** registrar stock para un `ProductId` de Catalog, **para** que el producto pueda venderse.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-03 | `ProductId` ≠ `Guid.Empty` |
| RN-04 | Stock inicial ≥ 0 |
| RN-05 | Un solo `StockEntry` por `ProductId` |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | **Agregado** `StockEntry` (Id = ProductId) |
| Dominio | **VO** `ProductReference` (snapshot nombre) |
| Aplicación | **Inbound port** `IRegisterStockUseCase` |
| Aplicación | **DTO** request/response stock |
| Infra | **Outbound** `IStockEntryRepository` |

### Criterios de aceptación

- [ ] **CA-01:** POST válido → stock consultable por GET.
- [ ] **CA-02:** Segundo registro mismo ProductId → conflicto o reabastecimiento según diseño MVP.
- [ ] **CA-03:** Se emite `StockEntryRegisteredDomainEvent`.

---

## HU-INV-02 — Consultar stock disponible

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |
| **Endpoint** | `GET /api/inventory/{productId}` |

**Como** operador o Orders, **quiero** conocer unidades disponibles, **para** validar ventas.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Inbound** `IGetStockByProductUseCase` |
| Aplicación | **DTO** `StockDto` |

### Criterios de aceptación

- [ ] **CA-04:** ProductId existente → `200` con `availableUnits`.
- [ ] **CA-05:** ProductId sin stock → `404`.

---

## HU-INV-03 — Reservar stock (confirmación de pedido)

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03 |
| **Endpoint** | `POST /api/inventory/reservations` |

**Como** Orders, **quiero** reservar unidades al confirmar un pedido, **para** evitar sobreventa.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-01 | No reservar más unidades de las disponibles |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | `StockEntry.Reserve(quantity)` |
| Dominio | **Evento** `StockReservedDomainEvent`, `StockDepletedDomainEvent` |
| Aplicación | **Inbound** `IReserveStockUseCase` |
| Aplicación | **DTO** con `orderId` y `lines[]` |

### Criterios de aceptación

- [ ] **CA-06:** Reserva exitosa decrementa `availableUnits`.
- [ ] **CA-07:** Stock insuficiente → `400`/`409`.
- [ ] **CA-08:** Confirmar pedido en Orders invoca este endpoint.

---

## HU-INV-04 — Liberar stock (cancelación)

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04 |
| **Endpoint** | `POST /api/inventory/reservations/release` |

**Como** Orders, **quiero** devolver unidades al cancelar un pedido confirmado, **para** recuperar inventario.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-02 | MVP: incrementar `availableUnits` por cantidad liberada |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | `StockEntry.Release(quantity)` |
| Dominio | **Evento** `StockReleasedDomainEvent` |
| Aplicación | **Inbound** `IReleaseStockUseCase` |

### Criterios de aceptación

- [ ] **CA-09:** Tras cancelar pedido Confirmed, stock aumenta.
- [ ] **CA-10:** Se emite `StockReleasedDomainEvent`.

---

## HU-INV-05 — Arquitectura hexagonal y persistencia

| Campo | Detalle |
|---|---|
| **Requerimientos** | RF-05, RF-06, RF-07, RF-08 |

**Como** alumno, **quiero** separar puertos inbound/outbound, **para** comparar con Clean Architecture de Catalog/Orders.

### Modelo requerido

| Tipo | Artefactos |
|---|---|
| **Inbound ports** | 4 use case interfaces |
| **Outbound ports** | `IStockEntryRepository`, `IIntegrationEventPublisher`, `IUnitOfWork` |
| **Driving adapter** | REST Controllers (solo dependen de inbound) |
| **Driven adapter** | EF Core, event logger |
| **DTO** | Contratos HTTP; **sin** exponer `StockEntry` en API |

### Criterios de aceptación

- [ ] **CA-11:** Controller no referencia repositorio EF directamente.
- [ ] **CA-12:** BD `ShopDemoInventory`, puerto **5435**.
- [ ] **CA-13:** Swagger en `/swagger`.
- [ ] **CA-14:** `docker compose up` funcional.

---

## Trazabilidad

| RF | Historia |
|---|---|
| RF-01 | HU-INV-01 |
| RF-02 | HU-INV-02 |
| RF-03 | HU-INV-03 |
| RF-04 | HU-INV-04 |
| RF-05–08 | HU-INV-05 |
