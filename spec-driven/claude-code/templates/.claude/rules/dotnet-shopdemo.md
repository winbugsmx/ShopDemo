# .NET ShopDemo architecture

## Per service

| Service | Pattern | Entry DI |
|---|---|---|
| Catalog | Clean + CQRS | `AddCatalogInfrastructure` |
| Orders | Clean + CQRS | `AddOrdersInfrastructure` |
| Inventory | Hexagonal | `AddInventoryInfrastructure` |
| Analytics | Aspire defaults | `AddServiceDefaults` |
| MCP | HTTP tools | `ShopDemoMcpTools` |

## Cross-cutting

- Event Hubs: `EventHubs__*` env vars
- K8s secrets: `shopdemo-secrets`
- Shared kernel: `ShopDemo.Shared`

Specs: `spec-driven/specs/01-catalog` through `12-mcp-gateway` (deploy: `06-deploy-azure`, `07-deploy-aws`)
