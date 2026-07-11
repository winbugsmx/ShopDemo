# Implementación — MCP Gateway (código)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |

**Requerimientos:** [REQUERIMIENTOS-INTEGRACION-IA.md](./REQUERIMIENTOS-INTEGRACION-IA.md)  
**Despliegue nube:** [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)  
**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md)  
**Código completo para copiar:** [ANEXO-CODIGO-MCP.md](./ANEXO-CODIGO-MCP.md)

---

## Índice

1. [Qué vas a integrar](#1-qué-vas-a-integrar)
2. [Paso 1 — Crear proyecto](#2-paso-1--crear-proyecto)
3. [Paso 2 — Copiar Program.cs](#3-paso-2--copiar-programcs)
4. [Paso 3 — Copiar ShopDemoMcpTools](#4-paso-3--copiar-shopdemomcptools)
5. [Paso 4 — Configuración y Docker](#5-paso-4--configuración-y-docker)
6. [Paso 5 — Ejecutar y validar](#6-paso-5--ejecutar-y-validar)

---

## 1. Qué vas a integrar

El **MCP Gateway** no modifica el dominio de negocio. Es un adaptador HTTP que expone **tools** para agentes IA (Cursor, Claude Code):

| Tool | Para qué sirve | API que llama |
|---|---|---|
| `CreateProduct` | Crear producto desde el agente | Catalog `POST /api/products` |
| `GetProductStock` | Consultar stock | Inventory `GET /api/inventory/{id}` |
| `ListAnalyticsEvents` | Ver eventos del bus | Analytics `GET /api/analytics/events` |
| `GetShopDemoStatus` | Ping de salud de las 3 APIs | `/health` de cada una |

**Prerequisito:** Catalog (8001), Inventory (8003) y Analytics (8004) en ejecución.

---

## 2. Paso 1 — Crear proyecto

```bash
cd I:\Curso\ShopDemo
mkdir AI\ShopDemo.Mcp.Api
dotnet new webapi -n ShopDemo.Mcp.Api -o Source/AI/ShopDemo.Mcp.Api -f net10.0
dotnet add Source/AI/ShopDemo.Mcp.Api package ModelContextProtocol.AspNetCore
dotnet add Source/AI/ShopDemo.Mcp.Api package Microsoft.AspNetCore.OpenApi
```

Agregar el proyecto a `Source/ShopDemo.slnx` en carpeta `/AI/`.

**Para qué:** host ASP.NET Core en puerto **8005** con transporte MCP HTTP en `/mcp`.

---

## 3. Paso 2 — Copiar Program.cs

**Ruta:** `Source/AI/ShopDemo.Mcp.Api/Program.cs`

**Para qué:** registra tres `HttpClient` (catalog, inventory, analytics), health check y el endpoint MCP.

Código completo en [ANEXO-CODIGO-MCP.md](./ANEXO-CODIGO-MCP.md).

---

## 4. Paso 3 — Copiar ShopDemoMcpTools

**Ruta:** `Source/AI/ShopDemo.Mcp.Api/Tools/ShopDemoMcpTools.cs`

**Para qué:** define las cuatro tools MCP que delegan en las APIs existentes.

Código completo en [ANEXO-CODIGO-MCP.md](./ANEXO-CODIGO-MCP.md).

---

## 5. Paso 4 — Configuración y Docker

### appsettings.json

```json
{
  "ShopDemo": {
    "CatalogApiBaseUrl": "http://localhost:8001",
    "InventoryApiBaseUrl": "http://localhost:8003",
    "AnalyticsApiBaseUrl": "http://localhost:8004"
  }
}
```

**Para qué:** URLs que el MCP usa para llamar a las APIs (en Docker: `host.docker.internal`).

### Plantilla Docker

```powershell
cd AI\ShopDemo.Mcp.Api
copy .env.example .env
docker compose up --build
```

| Archivo | Para qué sirve |
|---|---|
| `Dockerfile` | Imagen con contexto raíz del repo |
| `docker-compose.yml` | Publica puerto 8005 |
| `.env.example` | Plantilla de URLs de APIs |

---

## 6. Paso 5 — Ejecutar y validar

```bash
dotnet run --project Source/AI/ShopDemo.Mcp.Api
curl http://localhost:8005/health
```

**Postman:** carpeta **MCP Gateway → Health**.

**Agente IA:** configurar `.cursor/mcp.json` o `.mcp.json` con `http://localhost:8005/mcp` (ver [spec-driven/](../../spec-driven)).

---

## Siguiente paso

Desplegar en nube: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) o [AWS](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md). Manifiestos K8s: deployment en `k8s/azure/mcp/` o `k8s/aws/mcp/` + `k8s/mcp/service.yaml`.
