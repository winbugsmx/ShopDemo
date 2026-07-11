# Analytics + Aspire — ShopDemo

Documentación para **visibilidad de eventos de negocio** y orquestación local con **.NET Aspire**.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](./REQUERIMIENTOS-ANALYTICS-ASPIRE.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md](./HISTORIAS-USUARIO-ANALYTICS-ASPIRE.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md](./ANEXO-ESPECIFICACION-TECNICA-ANALYTICS-ASPIRE.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md](./ANEXO-HISTORIAS-TECNICAS-ANALYTICS-ASPIRE.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-ANALYTICS-ASPIRE.md](./ANEXO-PEDAGOGIA-ANALYTICS-ASPIRE.md) |

## Implementación

| Documento | Descripción |
|---|---|
| [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md) | Guía paso a paso |
| [ANEXO-CODIGO-ANALYTICS-ASPIRE.md](./ANEXO-CODIGO-ANALYTICS-ASPIRE.md) | Referencia código |
| [INTEGRACION-ASPIRE.md](../INTEGRACION-ASPIRE.md) | Visión general Aspire |

## Tópicos de Estudio relacionados

| # | Tópico | Enlace |
|---|---|---|
| 04 | Microservicios y mensajería | [04-microservicios-comunicacion.md](../../Documentación_De_Estudio_Del_Curso/04-microservicios-comunicacion.md) |
| 10 | Observabilidad | [10-observabilidad.md](../../Documentación_De_Estudio_Del_Curso/10-observabilidad.md) |

Índice: [Documentación_De_Estudio_Del_Curso/README.md](../../Documentación_De_Estudio_Del_Curso/README.md)

## Flujo de negocio

```
Catalog ──┐
Orders  ──┼──► Event Hubs ──► Inventory [inventory-service]
          │              └──► Analytics [analytics-service]
```

| Servicio | Puerto | Rol |
|---|---|---|
| Catalog | 8001 | Publica eventos |
| Orders | 8002 | Publica + HTTP Inventory |
| Inventory | 8003 | Consume eventos |
| **Analytics** | **8004** | Observa y expone eventos |

## Ejecución rápida

```bash
dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<CS>" \
  --project Source/Aspire/ShopDemo.AppHost
dotnet run --project Source/Aspire/ShopDemo.AppHost
```
