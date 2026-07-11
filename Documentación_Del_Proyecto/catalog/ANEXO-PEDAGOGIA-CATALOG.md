# Anexo — Pedagogía: Catalog (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |
| **Audiencia** | Instructor y alumno |

---

## 1. Objetivos de aprendizaje

Al completar esta implementación, el alumno será capaz de:

1. Modelar un **Aggregate Root** (`Product`) con Value Objects y Domain Events.
2. Aplicar **Clean Architecture** con dependencias hacia el dominio.
3. Implementar **CQRS** con MediatR (comandos y consultas).
4. Validar entrada con **FluentValidation** en la capa de aplicación.
5. Persistir agregados con **EF Core + PostgreSQL** sin contaminar el dominio.
6. Publicar **Domain Events** mediante un puerto de infraestructura.
7. Exponer endpoints REST documentados con **Swagger**.
8. Containerizar el servicio con **Docker Compose**.

---

## 2. Contexto pedagógico

Catalog es el **primer bounded context** de referencia del curso. Sirve de base arquitectónica para Orders e Inventory.

| Aspecto | Detalle del curso |
|---|---|
| Posición en el roadmap | Etapa 1 |
| Arquitectura enseñada | Clean Architecture + DDD + CQRS |
| Comparación posterior | Inventory usa hexagonal (etapa 3) |

---

## 3. Alcance pedagógico vs. producto

| Tema | En el curso | Fuera del curso |
|---|---|---|
| Outbox Pattern | No | Garantías exactly-once |
| RF-10 a RF-15 | Dominio listo; API opcional | Producción completa |
| Event Hubs | Etapas 5–11 | No obligatorio en MVP Catalog |

---

## 4. Entregables del alumno

| # | Entregable |
|---|---|
| 1 | Código en los 4 proyectos `ShopDemo.Catalog.*` |
| 2 | Migración EF Core aplicada |
| 3 | `docker-compose.yml` funcional |
| 4 | Captura de Swagger con `POST /api/products` exitoso |
| 5 | Producto visible en PostgreSQL (puerto 5433) |

---

## 5. Referencias de estudio

- [IMPLEMENTACION-CATALOG.md](./IMPLEMENTACION-CATALOG.md)
- [ANEXO-ESPECIFICACION-TECNICA-CATALOG.md](./ANEXO-ESPECIFICACION-TECNICA-CATALOG.md)
- [Documentación_De_Estudio_Del_Curso/01-patrones-diseno.md](../../Documentación_De_Estudio_Del_Curso/01-patrones-diseno.md)
- [Documentación_De_Estudio_Del_Curso/03-ddd-domain-driven-design.md](../../Documentación_De_Estudio_Del_Curso/03-ddd-domain-driven-design.md)
