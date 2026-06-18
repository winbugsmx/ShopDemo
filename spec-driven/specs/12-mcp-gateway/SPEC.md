# SPEC — MCP Gateway (ShopDemo.Mcp.Api)

## Objetivo

Desplegar y consumir el MCP Server que expone tools sobre Catalog, Inventory y Analytics.

## Referencias

- [REQUERIMIENTOS-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)
- Código: `AI/ShopDemo.Mcp.Api/`

## Criterios de aceptación

- [ ] `GET /health` → 200
- [ ] Endpoint `/mcp` accesible al agente
- [ ] `GetShopDemoStatus` reporta APIs alcanzables
- [ ] `k8s/mcp/` aplicado si despliegue es K8s

## Variables MCP

| Entorno | `ShopDemo__CatalogApiBaseUrl` ejemplo |
|---|---|
| Local | `http://localhost:8001` |
| K8s cluster | `http://shopdemo-catalog:8080` |
| ACA | `https://<fqdn-catalog>` |
