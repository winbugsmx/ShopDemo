# GitHub CLI — Environments y Secrets (ShopDemo)

Repositorio: **`winbugsmx/ShopDemo`**  
Prerequisito: [GitHub CLI](https://cli.github.com/) autenticado (`gh auth login`).

Documentos relacionados: [SECRETS-CHECKLIST.md](SECRETS-CHECKLIST.md) · [SETUP-GITHUB.md](SETUP-GITHUB.md) · [SETUP-GITHUB-PORTAL.md](SETUP-GITHUB-PORTAL.md) (portal web)

---

## 1. Crear environments

Los workflows usan cuatro environments. El quinto (`Prod`) es legacy y **no** lo referencian los YAML actuales.

```bash
# Sustituir owner/repo si aplica
REPO="winbugsmx/ShopDemo"

gh api --method PUT "repos/${REPO}/environments/azure"
gh api --method PUT "repos/${REPO}/environments/azure-aks"
gh api --method PUT "repos/${REPO}/environments/aws"
gh api --method PUT "repos/${REPO}/environments/aws-eks"
```

Verificar:

```bash
gh api "repos/${REPO}/environments" --jq '.environments[].name'
# Esperado: aws, aws-eks, azure, azure-aks  (+ Prod si existía antes)
```

> **Nota:** No uses `-f wait_timer=0` en la API REST; GitHub devuelve HTTP 422. Un `PUT` sin cuerpo (o con `{}`) basta para crear el environment.

Opcional — protección con revisores (lab):

```bash
gh api --method PUT "repos/${REPO}/environments/azure" \
  --input - <<'EOF'
{
  "reviewers": [],
  "deployment_branch_policy": null,
  "wait_timer": 0
}
EOF
```

---

## 2. Inventario de secrets (sesión anterior + estado objetivo)

### 2.1 Repositorio (compartidos)

| Secret | Estado en lab | Usado por |
|---|---|---|
| `EVENT_HUBS_CONNECTION_STRING` | ✅ Configurado | Todos los workflows |
| `EVENT_HUB_NAME` | ✅ Configurado (`shopdemo-events`) | ACA, ECS |

```bash
gh secret set EVENT_HUBS_CONNECTION_STRING --body "<connection-string-azure-event-hubs>"
gh secret set EVENT_HUB_NAME --body "shopdemo-events"
```

### 2.2 Environment `azure` (deploy-azure.yml — ACA)

| Secret | Estado en lab |
|---|---|
| `AZURE_CREDENTIALS` | ✅ |
| `ACR_NAME` | ✅ (`acrshopdemolab01`) |
| `AZURE_RG` | ✅ (`rg-shopdemo-lab`) |
| `ACA_ENV` | ✅ (`aca-env-shopdemo`) |
| `PG_CATALOG_CONN` | ✅ |
| `PG_ORDERS_CONN` | ✅ |
| `PG_INVENTORY_CONN` | ✅ |
| `STORAGE_CHECKPOINT_CONN` | ✅ |
| `INVENTORY_API_BASE_URL` | ⚠️ Completar (URL interna Inventory para Orders) |
| `MCP_CATALOG_URL` | ⚠️ Completar |
| `MCP_INVENTORY_URL` | ⚠️ Completar |
| `MCP_ANALYTICS_URL` | ⚠️ Completar |

```bash
ENV=azure

gh secret set AZURE_CREDENTIALS --env "$ENV" --body '<json-service-principal-sdk-auth>'
gh secret set ACR_NAME --env "$ENV" --body "acrshopdemolab01"
gh secret set AZURE_RG --env "$ENV" --body "rg-shopdemo-lab"
gh secret set ACA_ENV --env "$ENV" --body "aca-env-shopdemo"

gh secret set PG_CATALOG_CONN --env "$ENV" --body "<Host=...;Database=ShopDemoCatalog;...>"
gh secret set PG_ORDERS_CONN --env "$ENV" --body "<Host=...;Database=ShopDemoOrders;...>"
gh secret set PG_INVENTORY_CONN --env "$ENV" --body "<Host=...;Database=ShopDemoInventory;...>"
gh secret set STORAGE_CHECKPOINT_CONN --env "$ENV" --body "<azure-blob-connection-string>"

# Orders → Inventory (DNS interno ACA o FQDN)
gh secret set INVENTORY_API_BASE_URL --env "$ENV" --body "https://<fqdn-ca-shopdemo-inventory>"

# MCP Gateway → APIs (https:// en ACA)
gh secret set MCP_CATALOG_URL --env "$ENV" --body "https://<fqdn-ca-shopdemo-catalog>"
gh secret set MCP_INVENTORY_URL --env "$ENV" --body "https://<fqdn-ca-shopdemo-inventory>"
gh secret set MCP_ANALYTICS_URL --env "$ENV" --body "https://<fqdn-ca-shopdemo-analytics>"
```

Obtener FQDNs con Azure CLI:

```bash
RG=rg-shopdemo-lab
for app in catalog inventory analytics; do
  az containerapp show -n "ca-shopdemo-$app" -g "$RG" \
    --query "properties.configuration.ingress.fqdn" -o tsv
done
```

Service Principal (origen de `AZURE_CREDENTIALS`):

```bash
az ad sp create-for-rbac --name "github-shopdemo" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION-ID>/resourceGroups/rg-shopdemo-lab \
  --sdk-auth
```

### 2.3 Environment `azure-aks` (deploy-aks.yml — AKS)

| Secret | Obligatorio | Origen típico |
|---|---|---|
| `AZURE_CREDENTIALS` | Sí | Mismo JSON que `azure` |
| `ACR_NAME` | Sí | `.env.azure` → `acrshopdemolab01` |
| `AZURE_RG` | Sí | `rg-shopdemo-lab` |
| `AKS_CLUSTER_NAME` | Sí | `aks-shopdemo` |
| `K8S_NAMESPACE` | Opcional | `shopdemo` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | Repo o Event Hubs |
| `PG_CATALOG_CONN` | Sí* | In-cluster (`k8s/secrets.example.yaml`) |
| `PG_ORDERS_CONN` | Sí* | Idem |
| `PG_INVENTORY_CONN` | Sí* | Idem |
| `AZURITE_CHECKPOINT_CONN` | Sí* | Azurite in-cluster |
| `POSTGRES_USER` | Opcional | `ShopDemo` |
| `POSTGRES_PASSWORD` | Opcional | Lab postgres |

\* Usados por job `sync_secrets` (manual).

**Pendiente manual:** `AZURE_CREDENTIALS` (mismo JSON que `azure`) — ver §4 con `-AzureCredentialsFile`.

```bash
ENV=azure-aks

gh secret set AZURE_CREDENTIALS --env "$ENV" --body '<json-service-principal-sdk-auth>'
gh secret set ACR_NAME --env "$ENV" --body "acrshopdemolab01"
gh secret set AZURE_RG --env "$ENV" --body "rg-shopdemo-lab"
gh secret set AKS_CLUSTER_NAME --env "$ENV" --body "aks-shopdemo"
gh secret set K8S_NAMESPACE --env "$ENV" --body "shopdemo"

gh secret set EVENT_HUBS_CONNECTION_STRING --env "$ENV" --body "<connection-string>"

gh secret set PG_CATALOG_CONN --env "$ENV" --body "Host=shopdemo-postgres;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123!"
gh secret set PG_ORDERS_CONN --env "$ENV" --body "Host=shopdemo-postgres;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123!"
gh secret set PG_INVENTORY_CONN --env "$ENV" --body "Host=shopdemo-postgres;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123!"
gh secret set AZURITE_CHECKPOINT_CONN --env "$ENV" --body "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://shopdemo-azurite:10000/devstoreaccount1;"

gh secret set POSTGRES_USER --env "$ENV" --body "ShopDemo"
gh secret set POSTGRES_PASSWORD --env "$ENV" --body "ShopDemo123!"
```

Referencia lab AKS: `scripts/azure/deploy-aks-report.json` (Ingress `20.42.38.69` / `shopdemo.local`).

### 2.4 Environment `aws` (deploy-aws.yml — ECS)

| Secret | Estado en lab |
|---|---|
| `AWS_ACCESS_KEY_ID` | ✅ |
| `AWS_SECRET_ACCESS_KEY` | ✅ |
| `AWS_REGION` | ✅ (`us-east-2`) |
| `ECS_CLUSTER` | ✅ (`shopdemo-cluster`) |
| `LAB_PREFIX` | ✅ (`shopdemo`) |
| `PG_CATALOG_CONN` | ✅ |
| `PG_ORDERS_CONN` | ✅ |
| `PG_INVENTORY_CONN` | ✅ |
| `AZURITE_CHECKPOINT_CONN` | ✅ |
| `INVENTORY_API_BASE_URL` | ✅ |
| `MCP_CATALOG_URL` | ✅ |
| `MCP_INVENTORY_URL` | ✅ |
| `MCP_ANALYTICS_URL` | ✅ |
| `AWS_ROLE_ARN` | ⚠️ Opcional (OIDC; alternativa a access keys) |
| `EKS_CLUSTER_NAME` | ⚠️ Solo si reutilizas el mismo environment para EKS |

```bash
ENV=aws

gh secret set AWS_ACCESS_KEY_ID --env "$ENV" --body "<access-key>"
gh secret set AWS_SECRET_ACCESS_KEY --env "$ENV" --body "<secret-key>"
gh secret set AWS_REGION --env "$ENV" --body "us-east-2"
gh secret set ECS_CLUSTER --env "$ENV" --body "shopdemo-cluster"
gh secret set LAB_PREFIX --env "$ENV" --body "shopdemo"

gh secret set PG_CATALOG_CONN --env "$ENV" --body "<ssm-o-connection-string>"
gh secret set PG_ORDERS_CONN --env "$ENV" --body "<...>"
gh secret set PG_INVENTORY_CONN --env "$ENV" --body "<...>"
gh secret set AZURITE_CHECKPOINT_CONN --env "$ENV" --body "<azurite-ecs-connection-string>"

gh secret set INVENTORY_API_BASE_URL --env "$ENV" --body "http://inventory.shopdemo.local:8080"
gh secret set MCP_CATALOG_URL --env "$ENV" --body "http://<alb-catalog>"
gh secret set MCP_INVENTORY_URL --env "$ENV" --body "http://<alb-inventory>"
gh secret set MCP_ANALYTICS_URL --env "$ENV" --body "http://<alb-analytics>"

# Opcional OIDC (recomendado producción)
gh secret set AWS_ROLE_ARN --env "$ENV" --body "arn:aws:iam::905221885508:role/github-shopdemo"
```

### 2.5 Environment `aws-eks` (deploy-eks.yml — EKS)

| Secret | Obligatorio | Origen típico |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Sí* | Mismo que `aws` |
| `AWS_SECRET_ACCESS_KEY` | Sí* | Mismo que `aws` |
| `AWS_ROLE_ARN` | Recomendado | OIDC GitHub → IAM |
| `AWS_REGION` | Sí | `us-east-2` |
| `EKS_CLUSTER_NAME` | Sí | `shopdemo-eks` |
| `K8S_NAMESPACE` | Opcional | `shopdemo` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | Azure Event Hubs |
| `PG_*`, `AZURITE_CHECKPOINT_CONN` | Sí* | In-cluster (sync_secrets) |
| `POSTGRES_USER`, `POSTGRES_PASSWORD` | Opcional | Lab |

**Pendiente manual:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (mismos que `aws`) o `AWS_ROLE_ARN` (OIDC). El script los toma de `aws configure` si están en el perfil local.

```bash
ENV=aws-eks

gh secret set AWS_ACCESS_KEY_ID --env "$ENV" --body "<access-key>"
gh secret set AWS_SECRET_ACCESS_KEY --env "$ENV" --body "<secret-key>"
gh secret set AWS_REGION --env "$ENV" --body "us-east-2"
gh secret set EKS_CLUSTER_NAME --env "$ENV" --body "shopdemo-eks"
gh secret set K8S_NAMESPACE --env "$ENV" --body "shopdemo"

gh secret set AWS_ROLE_ARN --env "$ENV" --body "arn:aws:iam::905221885508:role/github-shopdemo"

gh secret set EVENT_HUBS_CONNECTION_STRING --env "$ENV" --body "<connection-string>"

gh secret set PG_CATALOG_CONN --env "$ENV" --body "Host=shopdemo-postgres;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123!"
gh secret set PG_ORDERS_CONN --env "$ENV" --body "Host=shopdemo-postgres;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123!"
gh secret set PG_INVENTORY_CONN --env "$ENV" --body "Host=shopdemo-postgres;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123!"
gh secret set AZURITE_CHECKPOINT_CONN --env "$ENV" --body "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://shopdemo-azurite:10000/devstoreaccount1;"

gh secret set POSTGRES_USER --env "$ENV" --body "ShopDemo"
gh secret set POSTGRES_PASSWORD --env "$ENV" --body "ShopDemo123!"
```

Referencia lab EKS: `scripts/aws/deploy-eks-report.json`.

---

## 3. Verificación (solo nombres, no valores)

```bash
gh secret list
gh secret list --env azure
gh secret list --env azure-aks
gh secret list --env aws
gh secret list --env aws-eks
```

---

## 4. Script de sincronización local

Para evitar teclear secretos repetidos, usa el script PowerShell del repo (lee `.env.azure`, `.env.aws` y valores K8s de lab):

```powershell
cd I:\Curso\ShopDemo
.\.github\scripts\sync-github-environments.ps1 -WhatIf   # vista previa
.\.github\scripts\sync-github-environments.ps1             # aplica cambios
```

Parámetros útiles:

| Parámetro | Descripción |
|---|---|
| `-Target azure-aks` | Solo un environment |
| `-SkipSensitive` | Solo nombres/IDs no secretos (ACR, RG, cluster) |
| `-AzureCredentialsFile` | Ruta a JSON del Service Principal |
| `-WhatIf` | Muestra qué se escribiría sin llamar a `gh` |

---

## 5. Mapa workflow → environment

| Workflow | Environment | Secrets críticos |
|---|---|---|
| `deploy-azure.yml` | `azure` | `AZURE_CREDENTIALS`, `ACR_NAME`, `ACA_ENV`, runtime ACA |
| `deploy-aks.yml` | `azure-aks` | `AZURE_CREDENTIALS`, `ACR_NAME`, `AKS_CLUSTER_NAME` |
| `deploy-aws.yml` | `aws` | AWS creds/OIDC, `ECS_CLUSTER`, runtime ECS |
| `deploy-eks.yml` | `aws-eks` | AWS creds/OIDC, `EKS_CLUSTER_NAME` |

---

## 6. Orden recomendado (bootstrap)

1. Crear los cuatro environments (§1).
2. Provisionar infra con scripts PowerShell locales.
3. Cargar secrets de repositorio (`EVENT_HUBS_*`).
4. Cargar `azure` y `aws` (ACA + ECS).
5. Copiar/sincronizar a `azure-aks` y `aws-eks` (§4).
6. Primer run manual: **Deploy AKS/EKS** con `sync_secrets` + `apply_manifests`.
7. Merge a `main` → despliegues automáticos.

---

## Referencias

- [docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) — URLs MCP en ACA
- [docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) — URLs MCP en ECS
- [k8s/secrets.example.yaml](../k8s/secrets.example.yaml) — connection strings in-cluster
