---
name: deploy-aws
description: Deploy ShopDemo to AWS (ECS or EKS). Use when user mentions AWS, ECS, EKS, or ECR.
---

# Deploy AWS

Read `deploy-config.md` in this folder.

Workflow:
1. Confirm target: ECS vs EKS
2. Follow `Documentación_Del_Proyecto/despliegue/aws/` or `Documentación_Del_Proyecto/despliegue/eks/` guides
3. Use `.github/workflows/deploy-aws.yml` for CI path
4. Verify ALB/Ingress and health probes
5. Postman `deploymentProfile=aws`

Do not run `az` commands in this skill.
