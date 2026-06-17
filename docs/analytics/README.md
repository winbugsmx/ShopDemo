# Analytics + Aspire — Material del curso

Documentación para la integración de **.NET Aspire** y el microservicio observador **ShopDemo.Analytics.Api** en **ShopDemo**.

## Documentos

| Documento | Descripción |
|---|---|
| [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](./REQUERIMIENTOS-ANALYTICS-ASPIRE.md) | Especificación funcional y técnica |
| [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md) | Guía paso a paso con código fuente completo |
| [INTEGRACION-ASPIRE.md](../INTEGRACION-ASPIRE.md) | Visión general de Aspire en la solución |

## Relación con los microservicios existentes

```
Catalog (8001)  ──┐
Orders  (8002)  ──┼──► Azure Event Hubs ──► Inventory (8003)  [consumer: inventory-service]
Inventory (8003)──┘                              Analytics (8004) [consumer: analytics-service]
```

**Aspire AppHost** orquesta los 4 APIs + PostgreSQL + Azurite + configuración centralizada de Event Hubs.

## Puertos

| Servicio | API | Rol |
|---|---|---|
| Catalog | 8001 | Publica eventos de dominio |
| Orders | 8002 | Publica eventos + HTTP a Inventory |
| Inventory | 8003 | Publica y consume eventos |
| **Analytics** | **8004** | Solo consume y expone eventos observados |
| Aspire Dashboard | ~15888 | Logs, trazas, URLs |

## Prerequisitos

- Catalog, Orders e Inventory implementados
- Azure Event Hubs configurado ([INTEGRACION-AZURE-EVENT-HUBS.md](../INTEGRACION-AZURE-EVENT-HUBS.md))
- .NET 10 SDK

## Ejecución rápida

```bash
# 1. Configurar connection string en AppHost (user secrets recomendado)
dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<TU_CONNECTION_STRING>" \
  --project Aspire/ShopDemo.AppHost

# 2. Levantar todo el stack
dotnet run --project Aspire/ShopDemo.AppHost
```
