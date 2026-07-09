# Microservicio Inventory — Material del curso

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Documentación para el bounded context **Inventory** en **ShopDemo**, con **arquitectura hexagonal** (Ports & Adapters).

## Documentos (5 capas)

| # | Documento | Capa | Audiencia | Descripción |
|---|---|---|---|---|
| 1 | [REQUERIMIENTOS-INVENTORY.md](./REQUERIMIENTOS-INVENTORY.md) | A — Negocio | PM, analista, negocio | Qué debe hacer el módulo: stock, reservas, liberación, CA-N |
| 2 | [HISTORIAS-USUARIO-INVENTORY.md](./HISTORIAS-USUARIO-INVENTORY.md) | A — Negocio | Igual | Historias de operador de inventario y ventas |
| 3 | [ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md](./ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md) | B — Técnica | Desarrollador | StockEntry, hexagonal, API, EF Core, Event Hubs, CA-T |
| 4 | [ANEXO-HISTORIAS-TECNICAS-INVENTORY.md](./ANEXO-HISTORIAS-TECNICAS-INVENTORY.md) | B — Técnica | Desarrollador / DevOps | Tareas HT-INV-* de implementación |
| 5 | [ANEXO-PEDAGOGIA-INVENTORY.md](./ANEXO-PEDAGOGIA-INVENTORY.md) | C — Pedagogía | Instructor y alumno | Objetivos de aprendizaje y entregables |

**Guía de implementación adicional:** [IMPLEMENTACION-INVENTORY.md](./IMPLEMENTACION-INVENTORY.md)

## Orden de lectura recomendado

### Para negocio o junior sin contexto técnico

1. `REQUERIMIENTOS-INVENTORY.md` — sección *Resumen en lenguaje llano*
2. `HISTORIAS-USUARIO-INVENTORY.md`

### Para desarrollador que implementa

1. `REQUERIMIENTOS-INVENTORY.md` — contexto de negocio
2. `HISTORIAS-USUARIO-INVENTORY.md` — qué debe lograr el sistema
3. `ANEXO-ESPECIFICACION-TECNICA-INVENTORY.md` — cómo construirlo
4. `ANEXO-HISTORIAS-TECNICAS-INVENTORY.md` — tareas técnicas detalladas
5. `IMPLEMENTACION-INVENTORY.md` — guía paso a paso
6. `ANEXO-PEDAGOGIA-INVENTORY.md` — solo si eres alumno del curso

## Relación entre los 3 microservicios

```
Catalog (8001)  →  define productos (ProductId)
       ↓
Inventory (8003)  →  registra y controla stock por ProductId
       ↓
Orders (8002)     →  al confirmar/cancelar pedido, reserva/libera stock en Inventory
```

## Puertos

| Servicio | API | PostgreSQL (host) |
|---|---|---|
| Catalog | 8001 | 5433 |
| Orders | 8002 | 5434 |
| **Inventory** | **8003** | **5435** |
