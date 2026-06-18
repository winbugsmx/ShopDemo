---
description: AWS deployment steps (ECS / EKS)
---

Deploy ShopDemo to **AWS** only.

References:
- `docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md`
- `docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md`
- `docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md`
- `.github/workflows/deploy-aws.yml`
- `spec-driven/specs/07-deploy-aws/SPEC.md`

Steps:
1. Confirm ECR, ECS cluster or EKS, Event Hubs connectivity
2. Build/push images or use GitHub Actions
3. Apply `k8s/` manifests if EKS
4. Verify ALB/Ingress and Postman `deploymentProfile=aws`

Do not mix Azure CLI commands. Spanish for user.
