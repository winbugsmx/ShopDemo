# API conventions — ShopDemo

| Service | Base path |
|---|---|
| Catalog | `/api/products` |
| Orders | `/api/orders` |
| Inventory | `/api/inventory` |
| Analytics | `/api/analytics/events` |
| MCP | `/mcp` (HTTP transport) |

- Errors: `application/problem+json` with `traceId`
- Swagger at `/swagger` in Development
- Postman variables: `catalogBaseUrl`, `ordersBaseUrl`, etc.

Full guide: `Documentación_Del_Proyecto/GUIA-ENDPOINTS.md`
