# Anexo — Pedagogía: Orders (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |
| **Audiencia** | Instructor y alumno |

---

## 1. Objetivos de aprendizaje

Al completar esta implementación, el alumno será capaz de:

1. Modelar un **Aggregate Root** (`Order`) con entidades hijas y Value Objects.
2. Aplicar **Clean Architecture** con separación estricta de capas.
3. Implementar **CQRS** con MediatR (comandos y consultas).
4. Persistir el agregado con **EF Core + PostgreSQL** sin contaminar el dominio.
5. Publicar **Domain Events** mediante un puerto de infraestructura.
6. Integrar bounded contexts vía **HTTP** (Orders → Inventory).
7. Exponer endpoints REST documentados con **Swagger**.
8. Containerizar el servicio con **Docker Compose**.

---

## 2. Contexto pedagógico

Orders es el **segundo bounded context** del curso. Reutiliza los patrones de Catalog y añade integración síncrona con Inventory.

| Aspecto | Detalle del curso |
|---|---|
| Posición en el roadmap | Etapa 2 |
| Arquitectura enseñada | Clean Architecture + DDD + CQRS |
| Sprints de referencia | Sprint 1 (Domain) + Sprint 2 (Infrastructure & Application) |
| Comparación posterior | Inventory usa hexagonal (etapa 3) |

---

## 3. Alcance pedagógico vs. producto

| Tema | En el curso | Fuera del curso |
|---|---|---|
| Outbox Pattern | No | Garantías exactly-once |
| Pagos y envíos | No | Flujo e-commerce completo |
| MarkAsShipped / Delivered | Dominio preparado; API opcional | Producción completa |
| Event Hubs | Etapas 5–11 | No obligatorio en MVP Orders |

---

## 4. Entregables del alumno

| # | Entregable |
|---|---|
| 1 | Código fuente en los 4 proyectos `ShopDemo.Orders.*` |
| 2 | Migración EF Core `InitialCreate` |
| 3 | `docker-compose.yml` y `Dockerfile` |
| 4 | Captura de Swagger con endpoints funcionando |
| 5 | Captura de pgAdmin mostrando `ShopDemoOrders` (puerto 5434) |
| 6 | Flujo E2E: crear pedido → confirmar (reserva stock) → cancelar (libera stock) |

---

## 5. Preguntas de reflexión

1. ¿Por qué Orders guarda snapshot de precio y nombre en lugar de consultar Catalog en cada lectura?
2. ¿Qué ventaja tiene confirmar el pedido solo después de reservar stock en Inventory?
3. ¿En qué capa debe vivir la orquestación HTTP hacia Inventory: handler, servicio de aplicación o controller?
4. ¿Qué diferencia hay entre un Domain Event y una llamada HTTP síncrona a otro microservicio?

---

## 6. Referencias de estudio

- [IMPLEMENTACION-ORDERS.md](./IMPLEMENTACION-ORDERS.md)
- [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](./ANEXO-ESPECIFICACION-TECNICA-ORDERS.md)
- [REQUERIMIENTOS-CATALOG.md](../catalog/REQUERIMIENTOS-CATALOG.md)
- [Documentación de Estudio del Curso/03-ddd-domain-driven-design.md](../../Documentación de Estudio del Curso/03-ddd-domain-driven-design.md)
- [Documentación de Estudio del Curso/02-arquitecturas-software.md](../../Documentación de Estudio del Curso/02-arquitecturas-software.md)
