# Integración de IA — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Material para **detección de anomalías**, **MCP Server** y **Semantic Kernel** (Event Hubs + anexo Kafka) en Azure y AWS.

## Documentos

| Tipo | Enlace |
|---|---|
| **Teoría** | [TEORIA-INTEGRACION-IA.md](./TEORIA-INTEGRACION-IA.md) |
| **Requerimientos IA** | [REQUERIMIENTOS-INTEGRACION-IA.md](./REQUERIMIENTOS-INTEGRACION-IA.md) |
| **Requerimientos despliegue MCP** | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md) |
| **Despliegue MCP Azure** (ACA + AKS) | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |
| **Despliegue MCP AWS** (ECS + EKS) | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |
| **Integración IA Azure** (anomalías, SK) | [azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md](./azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md) |
| **Integración IA AWS** | [aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md](./aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md) |

## Código en el repositorio

| Componente | Ruta | Puerto |
|---|---|---|
| **MCP Gateway** | [AI/ShopDemo.Mcp.Api](../../AI/ShopDemo.Mcp.Api/) | 8005 (`/mcp`) |

Herramientas MCP expuestas: `CreateProduct`, `GetProductStock`, `ListAnalyticsEvents`, `GetShopDemoStatus`.

## Objetivos del módulo

| # | Objetivo | Implementación en repo |
|---|---|---|
| 1 | Anomalías en métricas/logs | Documentación (KQL / Logs Insights + umbrales) |
| 2 | MCP Server .NET | `ShopDemo.Mcp.Api` |
| 3 | Semantic Kernel + mensajería | Documentación: **Event Hubs** (principal) + anexo **Kafka** |

## Relación con otros módulos

- [Observabilidad](../observabilidad/README.md) — agregación de logs previa
- [Event Hubs](../INTEGRACION-AZURE-EVENT-HUBS.md) — bus de eventos para SK
- [Despliegue](../despliegue/README.md) — ACA, AKS, ECS, EKS
