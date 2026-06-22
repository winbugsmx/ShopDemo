# Guía — Release Azure con script PowerShell (recomendada)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Tiempo estimado** | 2–4 h (infra + push imágenes + pruebas) |
| **Plataforma** | Azure Container Apps (ACA) |

**Índice del lab:** [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)  
**Alternativas:** [CLI](./GUIA-RELEASE-CLI-AZURE.md) · [Portal](./GUIA-RELEASE-PORTAL-AZURE.md)  
**Scripts:** [scripts/azure/](../../../scripts/azure/)

---

## Qué hace y qué NO hace el script

| Hace | No hace |
|---|---|
| Resource Group, Event Hubs, Storage, ACR | `docker build` / `docker push` |
| Log Analytics + ACA Environment | Crear imágenes en tu PC |
| PostgreSQL (ACI) + 5 Container Apps + MCP | Commitear secretos |
| Modo AKS: cluster + `k8s/secrets.yaml` + Ingress Helm | `kubectl apply` (tú después) |

---

## Prerrequisitos (checklist)

- [ ] Suscripción Azure activa
- [ ] [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) instalado
- [ ] [Docker Desktop](https://www.docker.com/products/docker-desktop/) (para push manual o build local)
- [ ] PowerShell 5.1+ o PowerShell 7
- [ ] Repo ShopDemo clonado
- [ ] Permiso **Contributor** en la suscripción o en el Resource Group (lab)

---

## Paso 0 — Nombres canónicos (`.env.azure`)

```powershell
cd I:\Curso\ShopDemo\scripts\azure
copy .env.azure.example .env.azure
notepad .env.azure
```

| Variable | Valor ejemplo | Dónde obtenerlo |
|---|---|---|
| `AZURE_SUBSCRIPTION_ID` | GUID | Portal → **Subscriptions** |
| `AZURE_LOCATION` | `eastus` | Región del curso |
| `RESOURCE_GROUP` | `rg-shopdemo-lab` | Tú eliges |
| `ACR_NAME` | `acrshopdemolab01` | **Único global** † |
| `EVENT_HUB_NAMESPACE` | `shopdemo-eh-ns-lab01` | **Único global** † |
| `EVENT_HUB_NAME` | `shopdemo-events` | Fijo curso |
| `STORAGE_ACCOUNT_NAME` | `shopdemochecklab01` | **Único global** † |
| `POSTGRES_PASSWORD` | `ShopDemo123!` | Tú defines |
| `POSTGRES_DNS_LABEL` | `shopdemo-pg-lab` | Único en región |
| `ACA_ENV_NAME` | `aca-env-shopdemo` | Fijo curso |
| `IMAGE_TAG` | `latest` | Tag en ACR |

† Si está ocupado, usa sufijo `02` en **todo** el lab.

---

## Paso 1 — Login Azure

```powershell
az login
az account set --subscription "<TU-SUBSCRIPTION-ID>"
az account show --query name -o tsv
```

---

## Paso 2 — Elegir modo y ejecutar

| Modo | Comando | Cuándo |
|---|---|---|
| **ACA** (recomendado lab corto) | `.\Deploy-AzureShopDemo.ps1 -Mode ACA` | Release serverless |
| **AKS** | `.\Deploy-AzureShopDemo.ps1 -Mode AKS` | Kubernetes en Azure (día aparte) |
| **All** | `.\Deploy-AzureShopDemo.ps1 -Mode All` | Lab completo |

```powershell
.\Deploy-AzureShopDemo.ps1 -Mode ACA
```

**Salida esperada:** URLs FQDN de `ca-shopdemo-catalog`, `orders`, `analytics`, `mcp` y FQDN interno de `inventory`.

Si faltan imágenes en ACR, el script **avisa** pero continúa — las apps no arrancarán hasta el Paso 3.

---

## Paso 3 — Publicar imágenes en ACR (obligatorio)

### Opción A — Build manual

```powershell
cd I:\Curso\ShopDemo
az acr login --name acrshopdemolab01   # tu ACR_NAME
$login = az acr show --name acrshopdemolab01 --query loginServer -o tsv

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $login/shopdemo-catalog:latest .
docker push $login/shopdemo-catalog:latest
# Repetir: orders, inventory, analytics, AI/ShopDemo.Mcp.Api/Dockerfile → shopdemo-mcp
```

Lista completa: [GUIA-RELEASE-CLI-AZURE.md § Build](./GUIA-RELEASE-CLI-AZURE.md#8-build-y-push-de-imágenes).

### Opción B — GitHub Actions

Secrets: `AZURE_CREDENTIALS`, `ACR_NAME`, `AZURE_RG`, `ACA_ENV`  
Workflow: [.github/workflows/deploy-azure.yml](../../../.github/workflows/deploy-azure.yml)

---

## Paso 4 — Validar

```powershell
# Sustituir por FQDN impreso por el script
curl https://<fqdn-catalog>/health
```

Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) — variables con FQDN de cada Container App.

---

## Paso 5 — Limpieza

```powershell
.\Remove-AzureShopDemo.ps1
# Escribir el nombre del Resource Group para confirmar
```

---

## Modo AKS (opcional)

Tras `-Mode AKS` o `All`:

1. Push imágenes a ACR (Paso 3)
2. Editar `k8s/*/deployment.yaml` → `acrshopdemolab01.azurecr.io/shopdemo-*:latest`
3. `kubectl apply -f k8s/` (orden en [k8s/README.md](../../../k8s/README.md))

Detalle: [GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md#aks).

---

## Solución de problemas

| Síntoma | Acción |
|---|---|
| `Image pull failed` | Completar Paso 3 (push ACR) |
| `Subscription not found` | Revisar `AZURE_SUBSCRIPTION_ID` en `.env.azure` |
| Nombre ACR/Storage ocupado | Cambiar sufijo `01` → `02` |
| Orders 502 al confirmar | Verificar `InventoryApi__BaseUrl` (script usa FQDN interno inventory) |
| Sin eventos Analytics | Event Hubs + Storage checkpoints — re-ejecutar script o ver [Portal](./GUIA-RELEASE-PORTAL-AZURE.md) |

---

## Referencias

- [scripts/azure/README.md](../../../scripts/azure/README.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-AZURE.md) (índice histórico)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
