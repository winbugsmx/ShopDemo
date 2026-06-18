# Scripts PowerShell — Release Azure (ShopDemo)

Automatización del laboratorio Azure del curso Lite Thinking. Complementa la documentación paso a paso; **no sustituye** el build de imágenes Docker.

## Documentación de apoyo

| Tema | Documento |
|---|---|
| Container Apps (ACA) | [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../../docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) |
| AKS + Kubernetes | [IMPLEMENTACION-DESPLIEGUE-AKS.md](../../docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |
| Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS.md](../../docs/INTEGRACION-AZURE-EVENT-HUBS.md) |
| MCP Gateway | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |
| Guía de desarrollo | [GUIA-DESARROLLO-INTEGRACIONES.md](../../docs/GUIA-DESARROLLO-INTEGRACIONES.md) |
| CI/CD GitHub | [.github/workflows/deploy-azure.yml](../../.github/workflows/deploy-azure.yml) |

## Archivos

| Archivo | Función |
|---|---|
| `.env.azure.example` | Plantilla de variables (copiar a `.env.azure`) |
| `Deploy-AzureShopDemo.ps1` | Provisiona infraestructura Azure |
| `Remove-AzureShopDemo.ps1` | Elimina el Resource Group del lab |

## Prerrequisitos

1. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) instalado
2. `az login` con una suscripción con permisos **Contributor** (o equivalente)
3. Para modo **AKS**: [kubectl](https://kubernetes.io/docs/tasks/tools/) y [Helm](https://helm.sh/docs/intro/install/)
4. **Imágenes en ACR** antes de que arranquen las Container Apps (el script no hace build)

## Valores que debes obtener o definir

### Del Portal Azure (o de tu administrador)

| Variable en `.env.azure` | Dónde obtenerla en Portal |
|---|---|
| `AZURE_SUBSCRIPTION_ID` | **Subscriptions** → tu suscripción → **Subscription ID** |
| `AZURE_LOCATION` | Región acordada (ej. `eastus`, `mexicocentral`) |

### Nombres que tú inventas (deben ser únicos globalmente donde aplique)

| Variable | Regla |
|---|---|
| `RESOURCE_GROUP` | Nombre del grupo (ej. `rg-shopdemo-lab`) |
| `ACR_NAME` | Solo `a-z` y `0-9`, 5–50 caracteres, **único en Azure** |
| `EVENT_HUB_NAMESPACE` | **Único global** (Event Hubs namespace) |
| `STORAGE_ACCOUNT_NAME` | **Único global**, solo minúsculas y números |
| `POSTGRES_DNS_LABEL` | Etiqueta DNS del ACI PostgreSQL (única en la región) |

### Valores con default en la plantilla

| Variable | Uso |
|---|---|
| `EVENT_HUB_NAME` | Canal de eventos (`shopdemo-events`) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | Credenciales del contenedor PostgreSQL (ACI) |
| `ACA_ENV_NAME` | Container Apps Environment |
| `AKS_CLUSTER_NAME` | Cluster Kubernetes (modo AKS/All) |
| `IMAGE_TAG` | Tag esperado en ACR (`latest` por defecto) |

### Lo que el script obtiene solo (no copies del Portal)

| Valor | Cómo |
|---|---|
| Event Hubs connection string | `az eventhubs namespace authorization-rule keys list` |
| Storage connection string | `az storage account show-connection-string` |
| FQDN PostgreSQL ACI | Tras crear el contenedor |
| FQDN de cada Container App | Tras crear ACA |
| ACR login server | `az acr show` |

## Uso rápido

> **Documentación paso a paso en el curso:** [IMPLEMENTACION-DESPLIEGUE-AZURE §0](../../docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md#0-script-powershell-automatizado-recomendado) · [README principal](../../README.md#release-azure)

```powershell
cd I:\Curso\ShopDemo\scripts\azure

# 1. Configurar variables
copy .env.azure.example .env.azure
notepad .env.azure   # Completar AZURE_SUBSCRIPTION_ID y nombres únicos

# 2. Login Azure
az login
az account set --subscription "<TU-SUBSCRIPTION-ID>"

# 3. Provisionar (elegir modo)
.\Deploy-AzureShopDemo.ps1 -Mode ACA    # Solo Container Apps
.\Deploy-AzureShopDemo.ps1 -Mode AKS    # Solo AKS + secrets.yaml
.\Deploy-AzureShopDemo.ps1 -Mode All    # ACA + AKS

# 4. Publicar imágenes (obligatorio antes de probar APIs)
#    Opción A: workflow GitHub Actions (secrets: AZURE_CREDENTIALS, ACR_NAME, AZURE_RG, ACA_ENV)
#    Opción B: build manual — ver IMPLEMENTACION-DESPLIEGUE-AZURE.md §6

# 5. Modo AKS — aplicar manifiestos (manual)
cd I:\Curso\ShopDemo
# Actualizar image: en k8s/*/deployment.yaml → <acr>.azurecr.io/shopdemo-*:latest
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl apply -f k8s/catalog/ k8s/orders/ k8s/inventory/ k8s/analytics/ k8s/mcp/ k8s/ingress/

# 6. Limpieza del lab
.\Remove-AzureShopDemo.ps1
```

## Modos del script

| Modo | Crea | No incluye |
|---|---|---|
| **ACA** | RG, Event Hubs, Storage, ACR, PostgreSQL ACI, 5 Container Apps | Build Docker, AKS |
| **AKS** | RG, Event Hubs, ACR, AKS, Ingress Helm, `k8s/secrets.yaml` | Build Docker, `kubectl apply`, ACA |
| **All** | Todo lo anterior (ACA + AKS) | Build Docker |

## Diferencia ACA vs AKS (checkpoints Event Hubs)

| Entorno | Almacén de checkpoints |
|---|---|
| **ACA** | **Storage Account** real de Azure (`STORAGE_ACCOUNT_NAME`) |
| **AKS** | **Azurite** dentro del cluster (`k8s/azurite/`), como en Minikube |

## Orden recomendado del curso

1. Código local + Event Hubs ([GUIA-DESARROLLO](../../docs/GUIA-DESARROLLO-INTEGRACIONES.md) etapas 1–6)
2. `Deploy-AzureShopDemo.ps1 -Mode ACA` + imágenes en ACR + pruebas Postman
3. `Deploy-AzureShopDemo.ps1 -Mode AKS` (o `-Mode All`) + `kubectl apply`
4. MCP y observabilidad según docs de integración IA y observabilidad

## Solución de problemas

| Síntoma | Acción |
|---|---|
| `Image pull failed` en ACA | Publica las 5 imágenes en ACR con tag `IMAGE_TAG` |
| `Completa el valor de AZURE_SUBSCRIPTION_ID` | Edita `.env.azure`; quita los marcadores `<<< >>>` |
| Nombre ACR/EH/Storage ya existe | Cambia el sufijo en `.env.azure` (deben ser únicos globalmente) |
| Orders 502 al confirmar | Verifica `InventoryApi__BaseUrl` (FQDN interno Inventory) |
| AKS `ImagePullBackOff` | Edita `k8s/*/deployment.yaml` con ruta ACR completa |

## Seguridad

- **No commitees** `.env.azure` ni `k8s/secrets.yaml`
- El script habilita **admin user** en ACR solo para facilitar el lab en ACA; en producción usa identidad administrada + `AcrPull`
