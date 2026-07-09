# Observabilidad — ShopDemo

Material para **métricas, logs, trazas y alertas** en ShopDemo desplegado en Azure y AWS.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-OBSERVABILIDAD.md](./REQUERIMIENTOS-OBSERVABILIDAD.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-OBSERVABILIDAD.md](./HISTORIAS-USUARIO-OBSERVABILIDAD.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD.md](./ANEXO-ESPECIFICACION-TECNICA-OBSERVABILIDAD.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md](./ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-OBSERVABILIDAD.md](./ANEXO-PEDAGOGIA-OBSERVABILIDAD.md) |

## Implementación por cloud

| Cloud | Enlace |
|---|---|
| Azure (ACA + AKS) | [azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md](./azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) |
| AWS (ECS + EKS) | [aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md](./aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) |
| Teoría | [TEORIA-OBSERVABILIDAD.md](./TEORIA-OBSERVABILIDAD.md) |

## Prerequisitos

APIs desplegadas: [despliegue/azure/](../despliegue/azure/) · [despliegue/aws/](../despliegue/aws/)

## Estado en código

| Capacidad | Catalog/Orders/Inventory | Analytics |
|---|---|---|
| traceId en errores | Sí | Sí |
| OpenTelemetry | No (fase actual) | Sí (ServiceDefaults) |
| Aspire Dashboard | Solo local con AppHost | Sí |
