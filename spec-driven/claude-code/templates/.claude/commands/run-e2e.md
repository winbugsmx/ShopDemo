---
description: Run E2E Postman checklist
---

E2E validation for ShopDemo.

1. Import `Documentación_Del_Proyecto/ShopDemo.postman_collection.json`
2. Set `deploymentProfile`: `local` | `azure` | `aws`
3. Run folder **E2E Flow** (Catalog → Orders → Inventory → Analytics)
4. If MCP running: test MCP tools via `Source/AI/ShopDemo.Mcp.Api` or deployed `/mcp`

Report pass/fail per step in Spanish.
