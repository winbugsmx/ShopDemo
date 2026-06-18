---
name: deploy-azure
description: Guide Azure deployment for ShopDemo (ACA, AKS, ACR, MCP). Use when user mentions Azure, ACA, AKS, or deploy-azure.
---

# Deploy Azure (ShopDemo)

**Spec:** `spec-driven/specs/06-deploy-azure/SPEC.md`

## Steps

1. Read SPEC and these docs:
   - `docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md`
   - `docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md` (if AKS)
   - `docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md` (if MCP)
2. Provide **Portal** and **CLI** instructions for each step (user may choose either).
3. Build/push images including `AI/ShopDemo.Mcp.Api/Dockerfile` when MCP is in scope.
4. Never paste real connection strings; reference secrets/Key Vault patterns.

## Validation

- Health URLs respond 200
- Postman variables updated to Azure FQDNs

Respond to user in Spanish.
