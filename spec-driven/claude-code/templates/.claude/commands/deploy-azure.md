---
description: Azure deployment steps (ACA / AKS)
---

Deploy ShopDemo to **Azure** only.

References:
- `Documentación_Del_Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md`
- `Documentación_Del_Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md`
- `Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md`
- `.github/workflows/deploy-azure.yml`
- `spec-driven/specs/06-deploy-azure/SPEC.md`

Steps:
1. Confirm prerequisites (ACR, ACA env, Event Hubs, secrets)
2. Build/push images or use GitHub Actions
3. Apply manifests under `k8s/` if AKS
4. Verify health endpoints and Postman `deploymentProfile=azure`

Do not mix AWS CLI commands. Spanish for user.
