# Observabilidad de microservicios — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Material del curso para **métricas, logs, trazas, agregación y correlación** en ShopDemo desplegado en **Azure** y **AWS**.

## Documentos

| Tipo | Enlace |
|---|---|
| **Teoría** | [TEORIA-OBSERVABILIDAD.md](./TEORIA-OBSERVABILIDAD.md) |
| **Requerimientos** | [REQUERIMIENTOS-OBSERVABILIDAD.md](./REQUERIMIENTOS-OBSERVABILIDAD.md) |
| **Implementación Azure** (ACA + AKS) | [azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](./azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) |
| **Implementación AWS** (ECS + EKS) | [aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md](./aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) |

## Estado actual en el código

| Capacidad | Catalog / Orders / Inventory | Analytics |
|---|---|---|
| Logs estructurados (`ILogger`) | Sí | Sí |
| `traceId` en respuestas de error | Sí (`ExceptionHandlingMiddleware`) | Sí |
| OpenTelemetry (métricas/trazas) | No (Fase actual) | Sí vía `ShopDemo.ServiceDefaults` |
| Health `/health`, `/alive` | Sí | Sí |
| Aspire Dashboard (local) | Solo con AppHost | Sí |

## Plataformas cubiertas

| Azure | AWS |
|---|---|
| Container Apps (ACA) | ECS Fargate |
| AKS | EKS |

**Prerequisitos:** APIs desplegadas según [despliegue/azure](../despliegue/azure/) y [despliegue/aws](../despliegue/aws/).
