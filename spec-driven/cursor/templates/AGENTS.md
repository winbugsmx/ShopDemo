# ShopDemo — Agent instructions (Cursor)

## Project

Multicloud .NET 10 e-commerce lab: Catalog, Orders, Inventory, Analytics, MCP Gateway.  
Orchestration: Aspire (local). Messaging: Azure Event Hubs. Deploy: Azure (ACA/AKS) and AWS (ECS/EKS).

## Spec-driven workflow

1. **Always** read the relevant `spec-driven/specs/<area>/SPEC.md` before coding.
2. Follow linked `docs/**/REQUERIMIENTOS` and `IMPLEMENTACION` documents.
3. Validate acceptance criteria in the SPEC when done.
4. User-facing replies: **Spanish**. Code comments: English, minimal.

## Build & test

```bash
dotnet build ShopDemo.slnx
```

## Key paths

| Area | Path |
|---|---|
| Specs | `spec-driven/specs/` |
| K8s | `k8s/` |
| MCP | `AI/ShopDemo.Mcp.Api/` |
| Course docs | `docs/` |

## Deploy commands

- Azure: use skill `deploy-azure` — spec `06-deploy-azure`
- AWS: use skill `deploy-aws` — spec `07-deploy-aws`
- Never mix Azure CLI and AWS CLI in one task unless user explicitly asks.

## Constraints

- Do not commit secrets (`.env`, `k8s/secrets.yaml`, connection strings).
- Minimize diff scope; match existing architecture per service.
- Phase 1: do not modify Catalog/Orders/Inventory `Program.cs` unless SPEC explicitly requires it.
