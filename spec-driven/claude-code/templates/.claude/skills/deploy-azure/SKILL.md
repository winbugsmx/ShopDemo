---
name: deploy-azure
description: Deploy ShopDemo to Azure (ACA or AKS). Use when user mentions Azure, ACA, AKS, or Azure Container Apps.
---

# Deploy Azure

Read `deploy-config.md` in this folder.

Workflow:
1. Confirm target: ACA vs AKS
2. Follow `Documentación_Del_Proyecto/despliegue/azure/` or `Documentación_Del_Proyecto/despliegue/aks/` guides
3. Use `.github/workflows/deploy-azure.yml` for CI path
4. Verify `/health` on all services + MCP if deployed
5. Postman `deploymentProfile=azure`

Do not run `aws` commands in this skill.
