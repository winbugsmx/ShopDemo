# Microservicio Catalog — Material del curso

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Documentación para el bounded context **Catalog** en **ShopDemo**, con **Clean Architecture + DDD + CQRS**.

## Documentos

| Documento | Descripción |
|---|---|
| [REQUERIMIENTOS-CATALOG.md](./REQUERIMIENTOS-CATALOG.md) | Especificación funcional y técnica |
| [HISTORIAS-USUARIO-CATALOG.md](./HISTORIAS-USUARIO-CATALOG.md) | Requerimientos en formato historia de usuario + criterios de aceptación |
| [IMPLEMENTACION-CATALOG.md](./IMPLEMENTACION-CATALOG.md) | Guía paso a paso con código actual y explicación de clases |

## Relación con otros microservicios

```
Catalog (8001)  →  define productos y emite ProductId
       ↓
Inventory (8003)  →  registra stock para ese ProductId
       ↓
Orders (8002)     →  crea pedidos referenciando ProductId
```

## Puertos

| Servicio | API | PostgreSQL (host) |
|---|---|---|
| **Catalog** | **8001** | **5433** |
| Orders | 8002 | 5434 |
| Inventory | 8003 | 5435 |
