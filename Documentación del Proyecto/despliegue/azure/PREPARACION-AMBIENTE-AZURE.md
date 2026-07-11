# Preparación del ambiente Azure — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Propósito** | Herramientas, permisos y cuotas **antes** del release ACA o AKS |

**Guías de release:** [Script](./GUIA-RELEASE-SCRIPT-AZURE.md) · [CLI](./GUIA-RELEASE-CLI-AZURE.md) · [Portal](./GUIA-RELEASE-PORTAL-AZURE.md)

---

## 1. Herramientas en tu PC

| Herramienta | ACA | AKS | Instalación |
|---|---|---|---|
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | ✓ | ✓ | `az version` |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | ✓ | ✓ | `docker version` |
| PowerShell 5.1+ | ✓ | ✓ | Windows nativo |
| [kubectl](https://kubernetes.io/Documentación del Proyecto/tasks/tools/) | — | ✓ | `kubectl version --client` |
| [Helm](https://helm.sh/Documentación del Proyecto/intro/install/) | — | ✓ | `helm version` |

### Verificación rápida

```powershell
az version
az login
az account show
docker version
kubectl version --client   # solo AKS
helm version               # solo AKS
```

---

## 2. Suscripción y permisos IAM

| Rol mínimo | Alcance | Uso |
|---|---|---|
| **Contributor** | Suscripción o Resource Group | Crear RG, ACR, Event Hubs, ACA, AKS |
| **User Access Administrator** (opcional) | RG | Asignar roles ACR pull a identidades |

### Login y suscripción

```powershell
az login
az account list -o table
az account set --subscription "<TU-SUBSCRIPTION-ID>"
az account show --query "{name:name,id:id,tenantId:tenantId}" -o json
```

### Extensiones Azure CLI (el script las instala; manualmente):

```powershell
az extension add --name containerapp --upgrade -y
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.ContainerInstance --wait
az provider register --namespace Microsoft.ContainerService --wait
```

---

## 3. Cuotas y límites del lab

| Recurso | Valor lab validado | Notas |
|---|---|---|
| Región | `eastus` | Alternativas: `eastus2`, `centralus` |
| AKS nodos | **2** × `Standard_B2s` | 2 vCPU, 4 GiB c/u |
| ACR SKU | Basic | 5 repos `shopdemo-*` |
| Event Hubs | Basic / Standard | Namespace + hub + **2 consumer groups** |
| Container Apps | 5 APIs + MCP | Modo ACA |

### Nombres únicos globales (†)

| Variable | Ejemplo | Regla |
|---|---|---|
| `ACR_NAME` | `acrshopdemolab01` | Solo `a-z` `0-9`, único en Azure |
| `EVENT_HUB_NAMESPACE` | `shopdemo-eh-ns-lab01` | Único global |
| `STORAGE_ACCOUNT_NAME` | `shopdemochecklab01` | Único global, minúsculas |

Si `01` está ocupado, cambia a `02` en **`.env.azure` y en todas las guías**.

---

## 4. Archivo `.env.azure`

```powershell
cd I:\Curso\ShopDemo\Source\scripts\azure
copy .env.azure.example .env.azure
notepad .env.azure
```

| Variable | ACA | AKS (lab validado) |
|---|---|---|
| `AZURE_SUBSCRIPTION_ID` | GUID Portal | GUID Portal |
| `AZURE_LOCATION` | `eastus` | `eastus` |
| `RESOURCE_GROUP` | `rg-shopdemo-lab` | `rg-shopdemo-lab` |
| `ACR_NAME` | `acrshopdemolab01` | `acrshopdemolab01` |
| `AKS_CLUSTER_NAME` | — | `aks-shopdemo` |
| `AKS_NODE_COUNT` | — | **`2`** |
| `AKS_NODE_VM_SIZE` | — | `Standard_B2s` |
| `IMAGE_TAG` | `latest` | `latest` |

---

## 5. Consumer groups Event Hubs (obligatorio para Analytics)

El script **no** crea consumer groups; debes crearlos en ACA y AKS:

```powershell
$RG = "rg-shopdemo-lab"
$EH_NS = "shopdemo-eh-ns-lab01"
$EH_NAME = "shopdemo-events"

az eventhubs eventhub consumer-group create -g $RG --namespace-name $EH_NS --eventhub-name $EH_NAME --name inventory-service
az eventhubs eventhub consumer-group create -g $RG --namespace-name $EH_NS --eventhub-name $EH_NAME --name analytics-service
```

---

## 6. Orden recomendado — elige **una** ruta

| Ruta | Documento | Tiempo |
|---|---|---|
| **Script** | [GUIA-RELEASE-SCRIPT-AZURE.md](./GUIA-RELEASE-SCRIPT-AZURE.md) | 2–4 h |
| **CLI** | [GUIA-RELEASE-CLI-AZURE.md](./GUIA-RELEASE-CLI-AZURE.md) | 6–10 h |
| **Portal** | [GUIA-RELEASE-PORTAL-AZURE.md](./GUIA-RELEASE-PORTAL-AZURE.md) | 8–12 h |

Pasos comunes:
1. Preparación (este documento)
2. Build/push 5 imágenes a ACR
3. Release **ACA** y/o **AKS** según la guía elegida
4. Validar Swagger / Ingress
5. Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md)

---

## 7. Comandos extras útiles

```powershell
# Listar recursos del lab
az resource list -g rg-shopdemo-lab -o table

# ACR repos
az acr repository list -n acrshopdemolab01 -o table

# AKS
az aks list -g rg-shopdemo-lab -o table
az aks get-credentials -g rg-shopdemo-lab -n aks-shopdemo --overwrite-existing

# Pods
kubectl get pods -n shopdemo
kubectl get ingress -n shopdemo
```
