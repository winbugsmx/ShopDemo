# Implementación — Despliegue Azure (índice)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Plataforma** | Azure Container Apps + ACR + ACI |
| **Alcance lab** | [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md) |

> La documentación paso a paso se dividió en **tres guías**. Para el release en 2–3 h usa la guía **Script**.

---

## Guías de release (elige una ruta)

| Guía | Tiempo | Cuándo usarla |
|---|---|---|
| [**GUIA-RELEASE-SCRIPT-AZURE**](./GUIA-RELEASE-SCRIPT-AZURE.md) | 2–4 h | **Recomendada** — `Deploy-AzureShopDemo.ps1` |
| [**GUIA-RELEASE-CLI-AZURE**](./GUIA-RELEASE-CLI-AZURE.md) | 6–10 h | Mismos recursos con `az` |
| [**GUIA-RELEASE-PORTAL-AZURE**](./GUIA-RELEASE-PORTAL-AZURE.md) | 8–12 h | Portal visual + capturas + enlaces Microsoft Learn |

**Scripts:** [scripts/azure/](../../../scripts/azure/) · **Variables:** [`.env.azure.example`](../../../scripts/azure/.env.azure.example)

**Kubernetes (AKS):** [GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md)

---

## Arquitectura de checkpoints

| Entorno | Almacén checkpoints | Servicio |
|---|---|---|
| **ACA (release)** | Azure Storage Account (Blob) | `shopdemochecklab01` |
| **AKS / Minikube** | Azurite in-cluster | `k8s/azurite/` |

En ACA **no** uses Azurite en ACI.

---

## Convención de nombres (fuente de verdad)

> Nombres con **†** deben ser únicos globalmente. Si `01` está ocupado, usa `02` en **todos** los archivos y en `.env.azure`.

| Recurso Azure | Nombre canónico | Variable `.env.azure` |
|---|---|---|
| Resource Group | `rg-shopdemo-lab` | `RESOURCE_GROUP` |
| Región | `eastus` | `AZURE_LOCATION` |
| Event Hubs namespace † | `shopdemo-eh-ns-lab01` | `EVENT_HUB_NAMESPACE` |
| Event Hub | `shopdemo-events` | `EVENT_HUB_NAME` |
| Consumer groups | `inventory-service`, `analytics-service` | — |
| Container Registry † | `acrshopdemolab01` | `ACR_NAME` |
| Log Analytics | `log-shopdemo` | `LOG_ANALYTICS_NAME` |
| ACA Environment | `aca-env-shopdemo` | `ACA_ENV_NAME` |
| PostgreSQL ACI | `aci-shopdemo-postgres` | `POSTGRES_ACI_NAME` |
| DNS label PG | `shopdemo-pg-lab` | `POSTGRES_DNS_LABEL` |
| Storage Account † | `shopdemochecklab01` | `STORAGE_ACCOUNT_NAME` |
| Blob containers | `inventory-checkpoints`, `analytics-checkpoints` | — |
| Container Apps | `ca-shopdemo-catalog`, `ca-shopdemo-inventory`, `ca-shopdemo-orders`, `ca-shopdemo-analytics`, `ca-shopdemo-mcp` | — |
| Imágenes ACR | `shopdemo-catalog`, `shopdemo-orders`, … | `IMAGE_TAG` |

**Login server ACR:** `acrshopdemolab01.azurecr.io`

---

## Servicios obligatorios (ACA)

| Servicio | ¿Se puede omitir? |
|---|---|
| Event Hubs + hub + consumer groups | No |
| ACR + 5 imágenes | No |
| Storage Account (checkpoints) | No |
| Log Analytics + ACA Environment | No |
| PostgreSQL ACI | No (lab) |
| 5 Container Apps | No |
| AKS | Sí en lab corto |
| GitHub Actions | Sí (push manual a ACR) |

---

## Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| `Image pull failed` | ACR sin credenciales en ACA | Revisar registry username/password en la app |
| API no arranca | Puerto incorrecto | `target-port 8080` y Dockerfile |
| Orders 502 al confirmar | URL Inventory incorrecta | `InventoryApi__BaseUrl` con FQDN **interno** |
| Sin eventos en Analytics | EH o consumer group | `EventHubs__Enabled`, grupo `analytics-service`, secreto storage |
| EF migration error | PG no accesible | Puerto 5432 en ACI; SSL en connection string |

---

## Referencias

- [TEORIA-CONTENEDORES-AZURE.md](./TEORIA-CONTENEDORES-AZURE.md)
- [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./REQUERIMIENTOS-DESPLIEGUE-AZURE.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
- [GUIA-DESARROLLO-INTEGRACIONES.md](../../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 7)
