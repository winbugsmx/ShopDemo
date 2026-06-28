# Configuración GitHub — ShopDemo CI/CD

Pasos para activar los **4 workflows** tras clonar el repo. Checklist de secrets: [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md).

**Elige tu camino:**

| Guía | Para quién |
|---|---|
| **[SETUP-GITHUB-PORTAL.md](SETUP-GITHUB-PORTAL.md)** | Alumnos que configuran desde el **portal web** de GitHub |
| **[GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md)** | Quienes prefieren **GitHub CLI** (`gh`) o automatizar con script |

## 1. Crear environments

En **Settings → Environments**, crear los cuatro nombres. **Paso a paso con capturas de ruta en portal:** [SETUP-GITHUB-PORTAL.md §3](SETUP-GITHUB-PORTAL.md#3-crear-environments).
| Environment | Protección recomendada (lab) |
|---|---|
| `azure` | Opcional: reviewers |
| `azure-aks` | Opcional |
| `aws` | Opcional |
| `aws-eks` | Opcional |

Con [GitHub CLI](https://cli.github.com/) (`gh auth login`) — **comandos completos y listado de secrets:** [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md)

```bash
REPO="winbugsmx/ShopDemo"
gh api --method PUT "repos/${REPO}/environments/azure"
gh api --method PUT "repos/${REPO}/environments/azure-aks"
gh api --method PUT "repos/${REPO}/environments/aws"
gh api --method PUT "repos/${REPO}/environments/aws-eks"
```

O con PowerShell (lee `.env.azure`, `.env.aws` y `k8s/secrets.example.yaml`):

```powershell
.\.github\scripts\sync-github-environments.ps1 -WhatIf
.\.github\scripts\sync-github-environments.ps1
```

## 2. Provisionar infra (una vez, local)

```powershell
# Azure ACA + AKS
cd scripts\azure
copy .env.azure.example .env.azure
.\Deploy-AzureShopDemo.ps1 -Mode All   # o ACA / AKS por separado

# AWS ECS + EKS
cd scripts\aws
copy .env.aws.example .env.aws
.\Deploy-AwsShopDemo.ps1 -Mode All   # o ECS / EKS por separado
```

Completar post-script AKS/EKS según [GUIA-RELEASE-SCRIPT-AZURE](../docs/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) y [GUIA-RELEASE-SCRIPT-AWS](../docs/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md).

## 3. Cargar secrets

Copia valores de `.env.azure`, `.env.aws` y consolas cloud.

| Método | Documento |
|---|---|
| **Portal GitHub** (Settings → Secrets) | [SETUP-GITHUB-PORTAL.md §4–§5](SETUP-GITHUB-PORTAL.md#4-secrets-a-nivel-repositorio) |
| **GitHub CLI** | [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md) |
| **Script PowerShell** | `sync-github-environments.ps1` (ver GH-CLI-COMMANDS §4) |

Mínimo por environment — ver tablas en [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md).
Ejemplo con `gh` (repository secret; repetir por environment en la UI):

```bash
gh secret set EVENT_HUBS_CONNECTION_STRING --body "<connection-string>"
gh secret set AZURE_CREDENTIALS --body '<service-principal-json>'
gh secret set ACR_NAME --body "acrshopdemolab01"
gh secret set AZURE_RG --body "rg-shopdemo-lab"
gh secret set AKS_CLUSTER_NAME --body "aks-shopdemo"
gh secret set AWS_REGION --body "us-east-2"
gh secret set EKS_CLUSTER_NAME --body "shopdemo-eks"
gh secret set ECS_CLUSTER --body "shopdemo-cluster"
```

> Los secrets de **runtime** (PostgreSQL, MCP URLs, Storage) deben coincidir con lo provisionado por los scripts.

## 4. Primer despliegue K8s (manual)

**Actions → Deploy AKS** (o **Deploy EKS**) → **Run workflow**:

| Input | Marcar |
|---|---|
| `sync_secrets` | ✓ primera vez |
| `apply_manifests` | ✓ primera vez |
| `apply_infra` | ✓ solo si postgres/azurite no existen en cluster |

## 5. Flujo habitual (merge a `main`)

1. PR → revisión → **merge a `main`**
2. Se ejecutan workflows según paths cambiados (ver [.github/README.md](README.md))
3. Verificar en **Actions** y probar `/health` / Swagger

## 6. Service Principal Azure (resumen)

```bash
az ad sp create-for-rbac --name "github-shopdemo" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION-ID>/resourceGroups/rg-shopdemo-lab \
  --sdk-auth
```

Pegar JSON en secret `AZURE_CREDENTIALS` (environments `azure` y `azure-aks`).

## 7. OIDC AWS (recomendado)

Ver [PREPARACION-AMBIENTE-AWS.md](../docs/despliegue/aws/PREPARACION-AMBIENTE-AWS.md) y políticas en `scripts/aws/iam-policy-shopdemo-lab-*.json`.

Secret `AWS_ROLE_ARN` en environments `aws` y `aws-eks`.

## Referencias

- [README.md](README.md) — índice workflows
- [SETUP-GITHUB-PORTAL.md](SETUP-GITHUB-PORTAL.md) — configuración desde el portal web (alumnos)
- [GH-CLI-COMMANDS.md](GH-CLI-COMMANDS.md) — comandos `gh` por environment y secrets del lab
- [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md) — checklist completo
- [ALCANCE-LAB-RELEASE.md](../docs/despliegue/ALCANCE-LAB-RELEASE.md) — CI/CD § merge a main
