# Microservicio Orders — Material del curso

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Documentación para el bounded context **Orders** en **ShopDemo**, con **Clean Architecture + DDD + CQRS**.

## Documentos (5 capas)

| # | Documento | Capa | Audiencia | Descripción |
|---|---|---|---|---|
| 1 | [REQUERIMIENTOS-ORDERS.md](./REQUERIMIENTOS-ORDERS.md) | A — Negocio | PM, analista, negocio | Qué debe hacer el módulo: ciclo de pedido, reglas RN-*, CA-N |
| 2 | [HISTORIAS-USUARIO-ORDERS.md](./HISTORIAS-USUARIO-ORDERS.md) | A — Negocio | Igual | Historias de cliente y operador con criterios de aceptación |
| 3 | [ANEXO-ESPECIFICACION-TECNICA-ORDERS.md](./ANEXO-ESPECIFICACION-TECNICA-ORDERS.md) | B — Técnica | Desarrollador | Agregado Order, API, MediatR, EF Core, Docker, CA-T |
| 4 | [ANEXO-HISTORIAS-TECNICAS-ORDERS.md](./ANEXO-HISTORIAS-TECNICAS-ORDERS.md) | B — Técnica | Desarrollador / DevOps | Tareas HT-ORD-* de implementación |
| 5 | [ANEXO-PEDAGOGIA-ORDERS.md](./ANEXO-PEDAGOGIA-ORDERS.md) | C — Pedagogía | Instructor y alumno | Objetivos de aprendizaje y entregables |

**Guía de implementación adicional:** [IMPLEMENTACION-ORDERS.md](./IMPLEMENTACION-ORDERS.md)

## Orden de lectura recomendado

### Para negocio o junior sin contexto técnico

1. `REQUERIMIENTOS-ORDERS.md` — sección *Resumen en lenguaje llano*
2. `HISTORIAS-USUARIO-ORDERS.md`

### Para desarrollador que implementa

1. `REQUERIMIENTOS-ORDERS.md` — contexto de negocio
2. `HISTORIAS-USUARIO-ORDERS.md` — qué debe lograr el sistema
3. `ANEXO-ESPECIFICACION-TECNICA-ORDERS.md` — cómo construirlo
4. `ANEXO-HISTORIAS-TECNICAS-ORDERS.md` — tareas técnicas detalladas
5. `IMPLEMENTACION-ORDERS.md` — guía paso a paso
6. `ANEXO-PEDAGOGIA-ORDERS.md` — solo si eres alumno del curso

## Tópicos de Estudio relacionados

| # | Tópico | Enlace |
|---|---|---|
| 02 | Arquitecturas | [02-arquitecturas-software.md](../../Documentación de Estudio del Curso/02-arquitecturas-software.md) |
| 03 | DDD | [03-ddd-domain-driven-design.md](../../Documentación de Estudio del Curso/03-ddd-domain-driven-design.md) |
| 04 | Microservicios | [04-microservicios-comunicacion.md](../../Documentación de Estudio del Curso/04-microservicios-comunicacion.md) |

Índice: [Documentación de Estudio del Curso/README.md](../../Documentación de Estudio del Curso/README.md)

## Relación con otros microservicios

```
Catalog (8001)  →  define productos (ProductId + precio snapshot)
       ↓
Orders (8002)   →  crea y confirma pedidos
       ↓
Inventory (8003)  →  reserva/libera stock al confirmar/cancelar
```

## Puertos

| Servicio | API | PostgreSQL (host) |
|---|---|---|
| Catalog | 8001 | 5433 |
| **Orders** | **8002** | **5434** |
| Inventory | 8003 | 5435 |
