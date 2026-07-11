# Anexo — Historias técnicas: Catalog (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Historias de negocio** | [HISTORIAS-USUARIO-CATALOG.md](./HISTORIAS-USUARIO-CATALOG.md) |
| **Especificación** | [ANEXO-ESPECIFICACION-TECNICA-CATALOG.md](./ANEXO-ESPECIFICACION-TECNICA-CATALOG.md) |
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

## HT-CAT-01 — Modelar agregado Product con comportamientos

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-02 |
| **Historia de negocio relacionada** | Reglas RN-CAT-07 a RN-CAT-10 |

**Como** desarrollador de dominio, **quiero** encapsular reglas en el agregado `Product`, **para** que la lógica no quede en controllers ni handlers.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Dominio | **Agregado** `Product` con `Create`, `UpdateDetails`, `ChangePrice`, `ReplenishStock`, `DeductStock`, `Deactivate` |
| Dominio | **Eventos** `ProductPriceChanged`, `StockReplenished`, `StockDepleted`, `ProductDeactivated` |

### Criterios (CA-T)

- [ ] **CA-T12:** Sin lógica de negocio en `ProductsController` (solo delega a MediatR).
- [ ] **CA-T13:** Operaciones sobre producto inactivo lanzan `ProductDomainException`.
- [ ] **CA-T08:** Dominio sin referencias a EF Core, ASP.NET ni MediatR.

---

## HT-CAT-02 — Persistir productos en PostgreSQL

| Campo | Detalle |
|---|---|
| **Requerimiento** | RF-03 |

**Como** sistema, **quiero** persistir agregados `Product` en PostgreSQL, **para** conservar el catálogo entre reinicios.

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Infra | `CatalogDbContext`, `ProductRepository`, migración `InitialCreate` |

### Criterios (CA-T)

- [ ] **CA-T09:** Tabla `products` tras migración.
- [ ] **CA-T10:** `GetByIdAsync` hidrata VOs correctamente.

---

## HT-CAT-03 — Validar entrada con FluentValidation

| Requerimiento | RF-05 |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| Aplicación | `CreateProductValidator`, `ValidationBehavior` |
| API | Problem Details vía middleware |

### Criterios (CA-T)

- [ ] **CA-T03:** Validación fallida → `400` con detalle de campos.
- [ ] **CA-T14:** Validador ejecuta antes del handler.

---

## HT-CAT-04 — Documentar API con Swagger

| Requerimiento | RF-06 |

**Como** desarrollador, **quiero** Swagger en Development, **para** probar endpoints.

### Criterios (CA-T)

- [ ] **CA-T05:** `/swagger` accesible.
- [ ] Título: **ShopDemo Catalog API v1**.

---

## HT-CAT-05 — Ejecutar en Docker Compose

| Requerimiento | RF-07, RF-08 |

### Reglas técnicas

| ID | Regla |
|---|---|
| RN-CAT-15 | Puerto API host: **8001**; PostgreSQL host: **5433** |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `Dockerfile`, `docker-compose.yml` |
| Infra | `DatabaseInitializer` |

### Criterios (CA-T)

- [ ] **CA-T06:** `docker compose up` levanta API y BD.
- [ ] **CA-T07:** Migraciones al iniciar.

---

## HT-CAT-06 — Manejo transversal de errores

| Requerimiento | RF-09 |

### Modelo requerido

| Capa | Artefacto |
|---|---|
| API | `ExceptionHandlingMiddleware` |
| Dominio | `ProductDomainException` |

### Criterios (CA-T)

- [ ] **CA-T11:** Dominio → `400 Bad Request` con `traceId`.

---

## Trazabilidad técnica

| RF | Historia técnica |
|---|---|
| RF-02 | HT-CAT-01 |
| RF-03 | HT-CAT-02 |
| RF-05 | HT-CAT-03 |
| RF-06 | HT-CAT-04 |
| RF-07, RF-08 | HT-CAT-05 |
| RF-09 | HT-CAT-06 |
