# CI/CD — GitHub Actions (ShopDemo)

Despliegue automático tras **merge a `main`** (no en apertura de PR). También disponible **workflow_dispatch** manual.

| Workflow | Plataforma | Environment GitHub | Servicios |
|---|---|---|---|
| [deploy-azure.yml](workflows/deploy-azure.yml) | Azure Container Apps | `azure` | 5 APIs + MCP |
| [deploy-aws.yml](workflows/deploy-aws.yml) | AWS ECS Fargate | `aws` | 5 APIs + MCP |
| [deploy-aks.yml](workflows/deploy-aks.yml) | Azure AKS | `azure-aks` | 5 APIs + MCP + Ingress |
| [deploy-eks.yml](workflows/deploy-eks.yml) | Amazon EKS | `aws-eks` | 5 APIs + MCP + Ingress |

**Checklist de secrets y prerequisitos:** [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md) · **Guía de configuración:** [SETUP-GITHUB.md](SETUP-GITHUB.md) · **Portal web (alumnos):** [SETUP-GITHUB-PORTAL.md](SETUP-GITHUB-PORTAL.md) · **Comandos `gh` CLI:** [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md)

**Tópicos de Estudio:** [09 — CI/CD y DevOps](../docs/teoria-entrevistas/09-ci-cd-devops.md) · [Índice](../docs/teoria-entrevistas/README.md)

## Scripts auxiliares

| Script | Uso |
|---|---|
| [configure-azure-containerapp.sh](scripts/configure-azure-containerapp.sh) | ACA — secretos + imagen |
| [sync-aws-ssm.sh](scripts/sync-aws-ssm.sh) | ECS — SSM Parameter Store |
| [deploy-ecs-service.sh](scripts/deploy-ecs-service.sh) | ECS — nueva task definition |
| [deploy-k8s-image.sh](scripts/deploy-k8s-image.sh) | AKS/EKS — `kubectl set image` + rollout |
| [apply-k8s-manifests.sh](scripts/apply-k8s-manifests.sh) | AKS/EKS — apply compartidos + `k8s/azure/` o `k8s/aws/` (2.º arg) |
| [sync-k8s-secrets.sh](scripts/sync-k8s-secrets.sh) | AKS/EKS — Secret `shopdemo-secrets` |
| [sync-github-environments.ps1](scripts/sync-github-environments.ps1) | Bootstrap — environments + secrets vía `gh` |

## Infraestructura previa (una vez)

Los workflows **actualizan imágenes y configuración**; no crean VPC, clusters ni Container Apps desde cero:

- Azure ACA: `scripts/azure/Deploy-AzureShopDemo.ps1 -Mode ACA`
- Azure AKS: `scripts/azure/Deploy-AzureShopDemo.ps1 -Mode AKS` + pasos post-script (Ingress, consumer groups)
- AWS ECS: `scripts/aws/Deploy-AwsShopDemo.ps1 -Mode ECS`
- AWS EKS: `scripts/aws/Deploy-AwsShopDemo.ps1 -Mode EKS` + perfil free-tier si aplica

## Trigger unificado (rama `main`)

| Cambios en… | Workflows que pueden ejecutarse |
|---|---|
| `Catalog/`, `Orders/`, `Inventory/`, `Analytics`, `MCP`, `Shared` | Los 4 (según secrets/environments configurados) |
| `k8s/**` | Solo `deploy-aks` (`k8s/azure/`), `deploy-eks` (`k8s/aws/`) |
| Solo docs | Ninguno |
