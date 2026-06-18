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

## Documentos

| Documento | Descripción |
|---|---|
| [REQUERIMIENTOS-INVENTORY.md](./REQUERIMIENTOS-INVENTORY.md) | Especificación funcional y técnica |
| [IMPLEMENTACION-INVENTORY.md](./IMPLEMENTACION-INVENTORY.md) | Guía paso a paso con código y explicación de clases |

## Relación entre los 3 microservicios

```
Catalog (8001)  →  define productos (ProductId)
       ↓
Inventory (8003)  →  registra y controla stock por ProductId
       ↓
Orders (8002)     →  al confirmar/cancelar pedido, reserva/libera stock en Inventory
```

## Puertos

| Servicio | API | PostgreSQL |
|---|---|---|
| Catalog | 8001 | 5433 |
| Orders | 8002 | 5434 |
| **Inventory** | **8003** | **5435** |
