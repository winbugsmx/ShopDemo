# Azure deploy config reference

| Artifact | Path |
|---|---|
| ACA guide | `docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md` |
| AKS guide | `docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md` |
| MCP Azure | `docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md` |
| CI workflow | `.github/workflows/deploy-azure.yml` |
| K8s manifests | `k8s/` |
| SPEC | `spec-driven/specs/06-deploy-azure/SPEC.md` |

Images: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp`

Secrets: Event Hubs connection string via `shopdemo-secrets` or ACA env vars.
