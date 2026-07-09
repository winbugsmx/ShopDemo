# AI — ShopDemo

Microservicios de **integración con agentes IA**.

## Proyectos

| Proyecto | Puerto | Descripción |
|---|---|---|
| [ShopDemo.Mcp.Api](./ShopDemo.Mcp.Api/) | 8005 | MCP Server HTTP — tools sobre Catalog, Inventory, Analytics |

## Inicio rápido

```bash
# Con APIs en localhost:8001, 8003, 8004
dotnet run --project AI/ShopDemo.Mcp.Api

curl http://localhost:8005/health
# MCP endpoint: http://localhost:8005/mcp
```

## Docker

```bash
cd AI/ShopDemo.Mcp.Api
copy .env.example .env
docker compose up --build
```

## Documentación

- [docs/integracion-ia/README.md](../docs/integracion-ia/README.md)
- **Tópico 12:** [12-integracion-ia-mcp.md](../docs/teoria-entrevistas/12-integracion-ia-mcp.md)
- **Despliegue en nube:** [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)
