# Microservicio Orders — Material del curso

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Documentación para el desarrollo del bounded context **Orders** en la solución **ShopDemo**.

## Documentos

| Documento | Audiencia | Descripción |
|---|---|---|
| [REQUERIMIENTOS-ORDERS.md](./REQUERIMIENTOS-ORDERS.md) | Alumnos | Qué construir: reglas de negocio, endpoints, criterios de aceptación |
| [HISTORIAS-USUARIO-ORDERS.md](./HISTORIAS-USUARIO-ORDERS.md) | Alumnos | Historias de usuario, reglas, modelo y criterios por RF |
| [IMPLEMENTACION-ORDERS.md](./IMPLEMENTACION-ORDERS.md) | Alumnos / Instructor | Código funcional de referencia capa por capa |

## Sprints de referencia

- Sprint 1: Domain Layer (Aggregates, Value Objects, Domain Events)
- Sprint 2: Infrastructure + Application (EF Core, CQRS, Docker)

## Microservicios en ShopDemo

| Servicio | Puerto API | Puerto PostgreSQL | Estado |
|---|---|---|---|
| Catalog | 8001 | 5433 | Implementado (referencia) |
| **Orders** | **8002** | **5434** | Por implementar |

## Orden de trabajo sugerido

1. Leer `REQUERIMIENTOS-ORDERS.md`
2. Implementar capa por capa siguiendo el orden de la sección 14
3. Validar con `IMPLEMENTACION-ORDERS.md` como guía de referencia
4. Probar con Swagger y pgAdmin

## Documentación relacionada

- [Arquitectura general](../ARQUITECTURA.md)
- [Cheat sheets](../cheat-sheets/README.md)
