# Scripts PowerShell — Release Azure (ShopDemo)

Automatización del laboratorio Azure del curso Lite Thinking. Complementa la documentación; **no hace build** de imágenes Docker.

## Documentación de apoyo

| Tema | Documento |
|---|---|
| Preparación IAM/cuotas | [PREPARACION-AMBIENTE-AZURE.md](../../docs/despliegue/azure/PREPARACION-AMBIENTE-AZURE.md) |
| **Script** | [GUIA-RELEASE-SCRIPT-AZURE.md](../../docs/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) |
| Portal visual | [GUIA-RELEASE-PORTAL-AZURE.md](../../docs/despliegue/azure/GUIA-RELEASE-PORTAL-AZURE.md) |
| Azure CLI manual | [GUIA-RELEASE-CLI-AZURE.md](../../docs/despliegue/azure/GUIA-RELEASE-CLI-AZURE.md) |
| AKS + Kubernetes | [GUIA-RELEASE-KUBERNETES.md](../../docs/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |
| Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS.md](../../docs/INTEGRACION-AZURE-EVENT-HUBS.md) |
| Reporte AKS lab | [deploy-aks-report.json](./deploy-aks-report.json) |
| CI/CD GitHub | [.github/workflows/deploy-azure.yml](../../.github/workflows/deploy-azure.yml) · [deploy-aks.yml](../../.github/workflows/deploy-aks.yml) · [SETUP-GITHUB.md](../../.github/SETUP-GITHUB.md) |

## Archivos

| Archivo | Función |
|---|---|
| `.env.azure.example` | Plantilla de variables |
| `Deploy-AzureShopDemo.ps1` | Provisionamiento (`-Mode ACA`, `AKS`, `All`) |
| `Remove-AzureShopDemo.ps1` | Limpieza del lab |
| `deploy-aks-report.json` | URLs validadas release AKS |

## Prerrequisitos

1. [PREPARACION-AMBIENTE-AZURE.md](../../docs/despliegue/azure/PREPARACION-AMBIENTE-AZURE.md)
2. Permiso **Contributor** en suscripción o RG
3. Para **AKS**: `kubectl`, `helm`
4. **Imágenes en ACR** antes de probar APIs

## Modos

| Modo | Crea | Post-manual (AKS) |
|---|---|---|
| **ACA** | RG, EH, Storage, ACR, ACI Postgres, 5 Container Apps + MCP | Consumer groups EH |
| **AKS** | RG, EH, ACR, AKS, `k8s/secrets.yaml` | Helm Ingress + health probe, apply compartidos + `k8s/azure/`, consumer groups |
| **All** | ACA + AKS | Todo lo anterior |

## Uso rápido

```powershell
cd I:\Curso\ShopDemo\scripts\azure
copy .env.azure.example .env.azure
notepad .env.azure
az login
az account set --subscription "<SUBSCRIPTION-ID>"

# Build/push ACR (ver GUIA-RELEASE-SCRIPT-AZURE §3)
.\Deploy-AzureShopDemo.ps1 -Mode AKS

# Pasos post-script AKS: ver GUIA-RELEASE-SCRIPT-AZURE §5.2
```

## Solución de problemas

| Síntoma | Acción |
|---|---|
| Analytics CrashLoopBackOff | Consumer group `analytics-service` en Event Hubs |
| Ingress timeout externo | Helm con `health-probe-request-path=/healthz` |
| Script falla en Ingress | Instalar Helm manual (guía Script §5.2.2) |
| Swagger 404 AKS | `ASPNETCORE_ENVIRONMENT=Development` |
| Ingress requiere hosts | `IP shopdemo.local` en archivo hosts |
| Image pull failed | Push 5 imágenes a ACR |

## Seguridad

- No commitees `.env.azure` ni `k8s/secrets.yaml`
