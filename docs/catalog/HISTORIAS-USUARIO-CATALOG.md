# Historias de Usuario — Microservicio Catalog (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-CATALOG.md](./REQUERIMIENTOS-CATALOG.md) |
| **Bounded Context** | Catalog |
| **Formato** | Historia de usuario + reglas + modelo + criterios de aceptación |

---

## Leyenda — Modelo requerido

| Símbolo | Significado |
|---|---|
| **Agregado** | Entidad raíz de dominio con invariantes |
| **Entidad** | Objeto con identidad dentro del agregado |
| **VO** | Value Object inmutable |
| **DTO** | Contrato API / Application (sin lógica de negocio) |
| **Puerto** | Interfaz de infraestructura (repositorio, event publisher) |
| **N/A** | No aplica artefacto de dominio |

---

## HU-CAT-01 — Registrar producto en catálogo

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-01 |
| **Endpoint** | `POST /api/products` |

**Como** administrador de catálogo, **quiero** registrar un nuevo producto con nombre, precio, stock y categoría, **para** que esté disponible en la plataforma y otros contextos (Inventory, Orders) puedan referenciarlo por `ProductId`.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-01 | El nombre debe tener entre 3 y 200 caracteres (`ProductName`) |
| RN-CAT-02 | El precio debe ser ≥ 0 con moneda ISO de 3 letras (`Money`) |
| RN-CAT-03 | El stock inicial debe ser ≥ 0 (`StockLevel`) |
| RN-CAT-04 | La categoría debe ser un valor del catálogo cerrado (`Category`) |
| RN-CAT-05 | No puede existir otro producto activo con el mismo nombre (unicidad) |
| RN-CAT-06 | Al crear, el producto queda **activo** por defecto |

### Modelo requerido

| Capa | Artefacto | Rol |
|---|---|---|
| Dominio | **Agregado** `Product` | Raíz del catálogo |
| Dominio | **VO** `ProductName`, `Money`, `StockLevel`, `Category` | Validación y semántica |
| Dominio | **Evento** `ProductCreatedDomainEvent` | Notificación de creación |
| Aplicación | **Comando** `CreateProductCommand` | Entrada del caso de uso |
| Aplicación | **Handler** `CreateProductHandler` | Orquestación |
| Aplicación | **Validador** `CreateProductValidator` | FluentValidation |
| Aplicación | **DTO** `ProductDto` | Respuesta API |
| API | **Request** `CreateProductRequest` | Body HTTP |
| Infra | **Puerto** `IProductRepository` | Persistencia |
| Infra | **Puerto** `IDomainEventPublisher` | Publicación de eventos |

### Criterios de aceptación

- [ ] **CA-01:** Dado un payload válido, cuando envío `POST /api/products`, entonces recibo `201 Created` con `ProductDto` incluyendo `id` generado.
- [ ] **CA-02:** Dado un nombre duplicado, cuando creo el producto, entonces recibo `409 Conflict`.
- [ ] **CA-03:** Dado nombre &lt; 3 caracteres o precio negativo, cuando creo el producto, entonces recibo `400 Bad Request`.
- [ ] **CA-04:** Dado producto creado, cuando consulto PostgreSQL (`products`), entonces existe el registro persistido.
- [ ] **CA-05:** Dado producto creado, entonces se emite `ProductCreatedDomainEvent` (visible en logs en desarrollo).

---

## HU-CAT-02 — Modelar agregado Product con comportamientos

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |

**Como** desarrollador de dominio, **quiero** encapsular reglas en el agregado `Product`, **para** que la lógica de negocio no quede en controllers ni handlers.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-07 | Solo productos **activos** pueden cambiar detalles, precio o stock |
| RN-CAT-08 | `ChangePrice` no genera evento si el precio es igual al actual |
| RN-CAT-09 | `DeductStock` valida disponibilidad en `StockLevel` |
| RN-CAT-10 | `Deactivate` es idempotente (desactivar dos veces no falla) |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | **Agregado** `Product` con métodos `Create`, `UpdateDetails`, `ChangePrice`, `ReplenishStock`, `DeductStock`, `Deactivate` |
| Dominio | **Eventos** `ProductPriceChanged`, `StockReplenished`, `StockDepleted`, `ProductDeactivated` |

### Criterios de aceptación

- [ ] **CA-06:** No existe lógica de negocio en `ProductsController` más allá de delegar a MediatR.
- [ ] **CA-07:** Operaciones sobre producto inactivo lanzan `ProductDomainException`.
- [ ] **CA-08:** El dominio no referencia EF Core, ASP.NET ni MediatR.

---

## HU-CAT-03 — Persistir productos en PostgreSQL

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03 |

**Como** sistema, **quiero** persistir agregados `Product` en PostgreSQL, **para** conservar el catálogo entre reinicios.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-11 | Base de datos dedicada: `ShopDemoCatalog` |
| RN-CAT-12 | Value Objects se mapean a columnas (`price_amount`, `price_currency`, etc.) |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Infra | **DbContext** `CatalogDbContext` |
| Infra | **Repositorio** `ProductRepository` → `IProductRepository` |
| Infra | **Migración** EF Core `InitialCreate` |
| Dominio | **N/A** (sin dependencia de EF) |

### Criterios de aceptación

- [ ] **CA-09:** Tabla `products` existe tras migración.
- [ ] **CA-10:** `GetByIdAsync` recupera agregado con VOs correctamente hidratados.

---

## HU-CAT-04 — Publicar eventos de dominio

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-04 |

**Como** plataforma de integración, **quiero** que Catalog publique eventos al crear o modificar productos, **para** que otros servicios reaccionen de forma desacoplada.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-13 | Los eventos se publican **después** de persistir el agregado (handler) |
| RN-CAT-14 | En desarrollo, el publisher puede ser logging (sin Event Hubs obligatorio en MVP Catalog) |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Puerto** `IDomainEventPublisher` |
| Infra | **Adaptador** `LoggingDomainEventPublisher` (dev) |
| Dominio | **Eventos** de dominio listados en requerimientos §6.4 |

### Criterios de aceptación

- [ ] **CA-11:** Tras `CreateProduct`, el log contiene `ProductCreatedDomainEvent`.
- [ ] **CA-12:** El handler no publica si la persistencia falla.

---

## HU-CAT-05 — Validar entrada de API

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-05 |

**Como** consumidor de la API, **quiero** mensajes de error claros cuando envío datos inválidos, **para** corregir el payload sin depurar el servidor.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | **Validador** FluentValidation por comando |
| Aplicación | **Behavior** `ValidationBehavior` en pipeline MediatR |
| API | **Problem Details** vía middleware |

### Criterios de aceptación

- [ ] **CA-13:** Validación fallida retorna `400` con detalle de campos.
- [ ] **CA-14:** El validador se ejecuta antes del handler.

---

## HU-CAT-06 — Documentar API con Swagger

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-06 |

**Como** alumno, **quiero** explorar endpoints en Swagger, **para** probar la API sin Postman obligatorio.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | Swashbuckle configurado en `Program.cs` |
| **N/A** | Sin DTO de dominio adicional |

### Criterios de aceptación

- [ ] **CA-15:** `/swagger` accesible en `Development`.
- [ ] **CA-16:** Título: **ShopDemo Catalog API v1**.

---

## HU-CAT-07 — Ejecutar en Docker Compose

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-07, RF-08 |

**Como** alumno, **quiero** levantar Catalog + PostgreSQL con un comando, **para** reproducir el entorno sin instalar PG local.

### Reglas de negocio

| ID | Regla |
|---|---|
| RN-CAT-15 | Puerto API host: **8001**; PostgreSQL host: **5433** |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `Dockerfile`, `docker-compose.yml` |
| Infra | `DatabaseInitializer` (migrate on startup) |

### Criterios de aceptación

- [ ] **CA-17:** `docker compose up` levanta API y BD.
- [ ] **CA-18:** Migraciones EF se aplican al iniciar (Development).

---

## HU-CAT-08 — Manejo transversal de errores

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-09 |

**Como** consumidor, **quiero** respuestas HTTP consistentes ante excepciones de dominio, **para** integrar clientes de forma predecible.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `ExceptionHandlingMiddleware` |
| Dominio | `ProductDomainException` |

### Criterios de aceptación

- [ ] **CA-19:** Excepciones de dominio → `400 Bad Request`.
- [ ] **CA-20:** Respuesta incluye `traceId` para correlación.

---

## Historias preparadas (dominio listo, API pendiente)

| HU | Requerimiento | Historia resumida | Modelo |
|---|---|---|---|
| HU-CAT-09 | RF-10 | Actualizar detalles de producto activo | Agregado `Product.UpdateDetails()` |
| HU-CAT-10 | RF-11 | Cambiar precio con evento | Agregado + `ProductPriceChangedDomainEvent` |
| HU-CAT-11 | RF-12 | Reabastecer stock | Agregado + `StockReplenishedDomainEvent` |
| HU-CAT-12 | RF-13 | Descontar stock | Agregado + `StockDepletedDomainEvent` |
| HU-CAT-13 | RF-14 | Desactivar producto | Agregado + `ProductDeactivatedDomainEvent` |
| HU-CAT-14 | RF-15 | Consultar productos (CQRS) | **Query** + **DTO** de lectura (sin agregado nuevo) |

---

## Trazabilidad

| Requerimiento | Historia |
|---|---|
| RF-01 | HU-CAT-01 |
| RF-02 | HU-CAT-02 |
| RF-03 | HU-CAT-03 |
| RF-04 | HU-CAT-04 |
| RF-05 | HU-CAT-05 |
| RF-06 | HU-CAT-06 |
| RF-07, RF-08 | HU-CAT-07 |
| RF-09 | HU-CAT-08 |
| RF-10–15 | HU-CAT-09–14 |
