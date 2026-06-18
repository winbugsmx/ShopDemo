# AWS deploy config reference

| Artifact | Path |
|---|---|
| ECS guide | `docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md` |
| EKS guide | `docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md` |
| MCP AWS | `docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md` |
| CI workflow | `.github/workflows/deploy-aws.yml` |
| K8s manifests | `k8s/` |
| SPEC | `spec-driven/specs/07-deploy-aws/SPEC.md` |

Images: same names as Azure, pushed to ECR.

Event Hubs: still Azure-hosted in this lab; configure connection string in ECS task env or K8s secret.
