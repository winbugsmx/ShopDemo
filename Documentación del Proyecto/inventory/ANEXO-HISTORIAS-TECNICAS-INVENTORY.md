# Anexo — Historias técnicas: Inventory (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Historias de negocio** | [HISTORIAS-USUARIO-INVENTORY.md](./HISTORIAS-USUARIO-INVENTORY.md) |
| **Especificación** | [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](./ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md) |
| **Capa** | B — Tareas de implementación |

> Historias orientadas al **equipo de desarrollo**. No son necesidades de usuario final.

---

## Leyenda — Modelo requerido

| Símbolo | Significado |
|---|---|
| **Agregado** | Entidad raíz de dominio |
| **VO** | Value Object |
| **DTO** | Contrato API sin lógica de negocio |
| **Puerto In** | Inbound port (driving) |
| **Puerto Out** | Outbound port (driven) |

---

## HT-INV-01 — Modelar agregado StockEntry

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01, RF-03, RF-04 |
| **Historia de negocio relacionada** | HU-INV-01, HU-INV-03, HU-INV-04 |

**Como** desarrollador de dominio, **quiero** encapsular reglas de stock en el agregado `StockEntry`, **para** que la lógica no quede en controllers ni use cases.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | **Agregado** `StockEntry` con `Register`, `Reserve`, `Release`, `Replenish` |
| Dominio | **VO** `ProductReference`, `Quantity` |
| Dominio | **Eventos** `StockEntryRegistered`, `StockReserved`, `StockReleased`, `StockDepleted` |

### Criterios (CA-T)

- [ ] **CA-T13:** Dominio sin referencias a EF Core ni ASP.NET.
- [ ] Reserva rechazada si excede `AvailableUnits`.
- [ ] Liberación incrementa `AvailableUnits`.

---

## HT-INV-02 — Implementar use cases hexagonales

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01, RF-02, RF-03, RF-04 |
| **Historia de negocio relacionada** | HU-INV-01 a HU-INV-04 |

**Como** desarrollador de aplicación, **quiero** implementar use cases que cumplan los inbound ports, **para** separar el núcleo de los adaptadores HTTP.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Puerto In** `IRegisterStockUseCase`, `IGetStockByProductUseCase`, `IReserveStockUseCase`, `IReleaseStockUseCase` |
| Aplicación | Implementaciones de use cases |
| Aplicación | **DTO** `StockDto`, requests de reserva/liberación |
| API | Controllers que dependen solo de inbound ports |

### Criterios (CA-T)

- [ ] **CA-T01:** Puertos In/Out explícitos.
- [ ] **CA-T02:** Use cases implementan inbound ports (sin MediatR).
- [ ] **CA-T03:** Controllers dependen solo de inbound ports.
- [ ] **CA-T15:** Controller no referencia repositorio EF directamente.

---

## HT-INV-03 — Persistir stock en PostgreSQL

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-05 |

**Como** sistema, **quiero** persistir agregados `StockEntry` en PostgreSQL dedicado, **para** conservar inventario entre reinicios.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Infra | `InventoryDbContext`, `StockEntryRepository`, migración `InitialCreate` |
| Dominio | **Puerto Out** `IStockEntryRepository`, `IUnitOfWork` |

### Criterios (CA-T)

- [ ] **CA-T12:** Migraciones se aplican al iniciar.
- [ ] Tabla `stock_entries` con `product_id` único.

---

## HT-INV-04 — Publicar eventos de integración

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-06 |

**Como** sistema, **quiero** publicar eventos al registrar, reservar o liberar stock, **para** que Analytics u otros servicios reaccionen.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Puerto Out** `IIntegrationEventPublisher` |
| Infra | Implementación con logging en desarrollo |

### Criterios (CA-T)

- [ ] **CA-T14:** `StockReservedDomainEvent` visible en logs al reservar.
- [ ] Eventos emitidos tras persistir correctamente.

---

## HT-INV-05 — Exponer endpoints REST

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01, RF-02, RF-03, RF-04 |

**Como** desarrollador, **quiero** exponer los cuatro endpoints de inventario, **para** integrar con Orders y pruebas manuales.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `InventoryController` con 4 acciones |
| API | DTOs de request/response sin exponer `StockEntry` |

### Criterios (CA-T)

- [ ] **CA-T04:** `POST /api/inventory/stock` → stock consultable por GET.
- [ ] **CA-T05:** `POST /api/inventory/reservations` decrementa unidades.
- [ ] **CA-T06:** Stock insuficiente → `400` o `409`.
- [ ] **CA-T07:** `POST /api/inventory/reservations/release` incrementa unidades.

---

## HT-INV-06 — Documentar API con Swagger

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-07 |

**Como** desarrollador, **quiero** Swagger en Development, **para** probar endpoints.

### Criterios (CA-T)

- [ ] **CA-T10:** `/swagger` accesible.
- [ ] Título: **ShopDemo Inventory API v1**.

---

## HT-INV-07 — Ejecutar en Docker Compose

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-08 |

### Reglas técnicas

| ID | Regla |
|---|---|
| RN-INV-09 | Puerto API host: **8003**; PostgreSQL host: **5435** |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `Dockerfile`, `docker-compose.yml` |
| Infra | `DatabaseInitializer` |

### Criterios (CA-T)

- [ ] **CA-T11:** `docker compose up` levanta API y BD.
- [ ] **CA-T12:** Migraciones al iniciar.

---

## HT-INV-08 — Verificar integración E2E con Orders

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03, RF-04 |
| **Historia de negocio relacionada** | HU-INV-03, HU-INV-04 |

**Como** alumno, **quiero** verificar el flujo completo Catalog → Inventory → Orders, **para** validar la integración entre bounded contexts.

### Flujo de prueba

| Paso | Servicio | Acción |
|---|---|---|
| 1 | Catalog | `POST /api/products` |
| 2 | Inventory | `POST /api/inventory/stock` |
| 3 | Orders | `POST /api/orders` |
| 4 | Orders | `POST /api/orders/{id}/confirm` |
| 5 | Inventory | `GET /api/inventory/{productId}` |
| 6 | Orders | `POST /api/orders/{id}/cancel` |

### Criterios (CA-T)

- [ ] **CA-T08:** Confirmar pedido reduce stock en Inventory.
- [ ] **CA-T09:** Cancelar pedido confirmado restaura stock.

---

## HT-INV-09 — Preparar consumer Event Hubs (etapas 5+)

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-06 (extensión) |

**Como** sistema, **quiero** consumir eventos de Catalog desde Event Hubs, **para** reaccionar a creación de productos sin polling.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Infra | Consumer group `inventory-service` en hub `shopdemo-events` |
| Infra | Handler para `ProductCreated` (opcional en MVP) |

### Criterios (CA-T)

- [ ] Consumer group configurado en despliegue nube.
- [ ] En MVP local, registro manual de stock sigue siendo válido.

---

## Trazabilidad técnica

| RF | Historia técnica |
|---|---|
| RF-01 | HT-INV-01, HT-INV-02, HT-INV-05 |
| RF-02 | HT-INV-02, HT-INV-05 |
| RF-03 | HT-INV-01, HT-INV-02, HT-INV-05, HT-INV-08 |
| RF-04 | HT-INV-01, HT-INV-02, HT-INV-05, HT-INV-08 |
| RF-05 | HT-INV-03 |
| RF-06 | HT-INV-04, HT-INV-09 |
| RF-07 | HT-INV-06 |
| RF-08 | HT-INV-07 |
