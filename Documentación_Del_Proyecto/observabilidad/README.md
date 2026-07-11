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
| Teoría lab | [TEORIA-OBSERVABILIDAD.md](./TEORIA-OBSERVABILIDAD.md) |
| Tópico 10 (teoría general) | [10-observabilidad.md](../../Documentación_De_Estudio_Del_Curso/10-observabilidad.md) |

Índice Tópicos de Estudio: [Documentación_De_Estudio_Del_Curso/README.md](../../Documentación_De_Estudio_Del_Curso/README.md)

## Prerequisitos

APIs desplegadas: [despliegue/azure/](../despliegue/azure/) · [despliegue/aws/](../despliegue/aws/)

## Estado en código

| Capacidad | Source/Catalog, Source/Orders, Source/Inventory | Analytics |
|---|---|---|
| traceId en errores | Sí | Sí |
| OpenTelemetry | No (fase actual) | Sí (ServiceDefaults) |
| Aspire Dashboard | Solo local con AppHost | Sí |
