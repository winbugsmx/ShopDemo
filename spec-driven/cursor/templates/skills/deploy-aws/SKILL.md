---
name: deploy-aws
description: Guide AWS deployment for ShopDemo (ECS, EKS, ECR, MCP). Use when user mentions AWS, ECS, EKS, or deploy-aws.
---

# Deploy AWS (ShopDemo)

**Spec:** `spec-driven/specs/07-deploy-aws/SPEC.md`

## Steps

1. Read SPEC and:
   - `Documentación_Del_Proyecto/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md`
   - `Documentación_Del_Proyecto/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md` (if EKS)
   - `Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md` (if MCP)
2. Provide **Console** and **CLI** steps.
3. ECR repos for all services including `shopdemo-mcp`.
4. CloudWatch log groups per ECS service.

## Validation

- ALB/Ingress health checks pass
- Event Hubs reachable from tasks/pods

Respond to user in Spanish.
