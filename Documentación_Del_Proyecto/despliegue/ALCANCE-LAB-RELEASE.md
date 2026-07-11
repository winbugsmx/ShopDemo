# Alcance del laboratorio de release (2 días · pocas horas)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |

**Objetivo:** Que el alumno complete un **release funcional** sin perderse en decenas de pasos manuales.

---

## Rutas recomendadas por tiempo disponible

| Tiempo | Azure | AWS | Kubernetes |
|---|---|---|---|
| **~3 h (mínimo)** | [Script ACA](./azure/GUIA-RELEASE-SCRIPT-AZURE.md) + push ACR | [Script ECS](./aws/GUIA-RELEASE-SCRIPT-AWS.md) + push ECR | Omitir o solo [Minikube](./kubernetes/GUIA-RELEASE-KUBERNETES.md) local |
| **~6 h (cómodo)** | Script + validación Postman | Script + validación Postman | Minikube `kubectl apply` |
| **~12 h (completo)** | Script + leer [Portal](./azure/GUIA-RELEASE-PORTAL-AZURE.md) | Script + [Portal](./aws/GUIA-RELEASE-PORTAL-AWS.md) | Minikube + **un** cloud K8s (AKS **o** EKS, no ambos) |

> **Regla del curso:** para el release en la nube, **usa primero el script**. Las guías Portal y CLI sirven para **entender** cada servicio o si el script no está disponible.

---

## ¿Qué servicios son obligatorios?

### Azure Container Apps (release serverless)

| Servicio | ¿Obligatorio? | ¿Por qué? | ¿Lo crea el script? |
|---|---|---|---|
| Suscripción + `az login` | Sí | Autenticación | — |
| Resource Group | Sí | Agrupar el lab | Sí |
| Event Hubs + hub + consumer groups | Sí | Mensajería del código | Sí |
| Azure Container Registry (ACR) | Sí | Imágenes Docker | Sí |
| Storage Account (Blob) | Sí | Checkpoints Source/Inventory/Analytics en ACA | Sí |
| Log Analytics + ACA Environment | Sí | Requisito de Container Apps | Sí |
| PostgreSQL en ACI | Sí (lab) | 3 bases de datos | Sí |
| 5 Container Apps (4 APIs + MCP) | Sí | Release ShopDemo | Sí |
| **AKS** | **No** en lab corto | Avanzado; otro día | Modo `-Mode AKS` |
| **GitHub Actions** | Opcional | Automatizar build/deploy tras merge a `main` | No crea infra — [SECRETS-CHECKLIST](../../.github/SECRETS-CHECKLIST.md) |

**No necesitas en ACA:** Azurite en ACI (solo Kubernetes/ECS usan Azurite para checkpoints).

### AWS ECS Fargate

| Servicio | ¿Obligatorio? | ¿Por qué? | ¿Lo crea el script? |
|---|---|---|---|
| Usuario IAM + política | Sí | Permisos AWS | — (ver [Script AWS §0](./aws/GUIA-RELEASE-SCRIPT-AWS.md)) |
| `aws configure` | Sí | Credenciales CLI | — |
| Event Hubs (Azure) | Sí | Connection string cross-cloud | — (pegar en `.env.aws`) |
| ECR (5 repos) | Sí | Imágenes | Sí |
| VPC + subnets + IGW | Sí | Red Fargate | Sí |
| 3 Security Groups | Sí | ALB / apps / datos | Sí |
| ECS cluster | Sí | Orquestación | Sí |
| SSM Parameter Store | Sí | Secretos | Sí |
| PostgreSQL Fargate | Sí (lab) | Bases de datos | Sí |
| Azurite Fargate | Sí | Checkpoints EH en ECS | Sí |
| Cloud Map | Sí | Orders → Inventory por DNS | Sí |
| ALB × 4 APIs + MCP | Sí | APIs públicas | Sí |
| **EKS** | **No** en lab corto | Avanzado | Modo `-Mode EKS` |
| NAT Gateway | **No** | Lab usa subnets públicas (más barato) | — |

**Simplificación real:** hacer Portal/CLI **servicio por servicio** para ECS lleva **más de un día**. El script condensa ~40 pasos en uno.

### Kubernetes (local / AKS / EKS)

| Enfoque | ¿Cuándo? | Esfuerzo |
|---|---|---|
| **Minikube** + `k8s/` | Entender manifiestos sin costo cloud | ~4 h |
| **AKS** (`-Mode AKS`) | Azure + ya dominas ACA | +2–3 h tras script |
| **EKS** (`-Mode EKS`) | AWS + ya dominas ECS | +2–3 h tras script |

No es obligatorio desplegar **ACA + ECS + Minikube + AKS + EKS** en el mismo alumno.

---

## Documentación separada por plataforma

### Azure

| Documento | Uso |
|---|---|
| [GUIA-RELEASE-SCRIPT-AZURE.md](./azure/GUIA-RELEASE-SCRIPT-AZURE.md) | Ejecutar `Deploy-AzureShopDemo.ps1` |
| [GUIA-RELEASE-CLI-AZURE.md](./azure/GUIA-RELEASE-CLI-AZURE.md) | Mismos recursos con `az` |
| [GUIA-RELEASE-PORTAL-AZURE.md](./azure/GUIA-RELEASE-PORTAL-AZURE.md) | Portal visual + enlaces Microsoft Learn + espacio capturas |

### AWS

| Documento | Uso |
|---|---|
| [GUIA-RELEASE-SCRIPT-AWS.md](./aws/GUIA-RELEASE-SCRIPT-AWS.md) | Ejecutar `Deploy-AwsShopDemo.ps1` + IAM |
| [GUIA-RELEASE-CLI-AWS.md](./aws/GUIA-RELEASE-CLI-AWS.md) | Mismos recursos con `aws` |
| [GUIA-RELEASE-PORTAL-AWS.md](./aws/GUIA-RELEASE-PORTAL-AWS.md) | Consola visual + enlaces AWS Docs + capturas |

### Kubernetes

| Documento | Uso |
|---|---|
| [GUIA-RELEASE-KUBERNETES.md](./kubernetes/GUIA-RELEASE-KUBERNETES.md) | Minikube, AKS y EKS — qué elegir y en qué orden |
| [k8s/README.md](../../k8s/README.md) | Estructura: compartidos + `local/` / `azure/` / `aws/` |

> **Regla transversal:** Services, Postgres, Azurite e Ingress son **compartidos** en `k8s/`. Los **Deployments** van en la carpeta del cloud: `k8s/local/` (Minikube), `k8s/azure/` (ACR/AKS) o `k8s/aws/` (ECR/EKS). **No apliques `k8s/aws/` en AKS** ni `k8s/azure/` en EKS — provoca `ImagePullBackOff`.

---

## Convención de nombres (no mezclar variantes)

Copiar siempre de:

- Azure: `Source/scripts/azure/.env.azure.example`
- AWS: `Source/scripts/aws/.env.aws.example`

Si un nombre global está ocupado, cambia el sufijo `01` → `02` en **todos** los documentos y en el `.env`.

---

## Convención: alcance del curso

En los documentos de **requerimientos**, la sección **«No incluido en el curso»** delimita límites permanentes del laboratorio (enterprise, `azd`, multi-región, etc.). No indica etapas pendientes: integraciones ya cubiertas (Event Hubs, Aspire local, `k8s/`, ACA, ECS, AKS, EKS, MCP) están en el [README](../../README.md#etapas-del-curso-roadmap).

---

## CI/CD — merge a `main`

Tras configurar secrets ([.github/SECRETS-CHECKLIST.md](../../.github/SECRETS-CHECKLIST.md)), un **merge a `main`** dispara automáticamente:

| Workflow | Destino |
|---|---|
| `deploy-azure.yml` | Azure Container Apps (5 servicios) |
| `deploy-aws.yml` | AWS ECS Fargate (5 servicios) |
| `deploy-aks.yml` | Azure AKS — build ACR + `kubectl set image` |
| `deploy-eks.yml` | Amazon EKS — build ECR + `kubectl set image` |

- **No** despliega al abrir el PR; solo al integrar en `main`.
- Infra inicial sigue siendo con scripts PowerShell (una vez).
- Cambios en `k8s/**` actualizan manifiestos en AKS (`k8s/azure/`) y EKS (`k8s/aws/`) vía CI/CD (no ACA/ECS).

Índice completo: [.github/README.md](../../.github/README.md) · Configuración: [SETUP-GITHUB.md](../../.github/SETUP-GITHUB.md) · **Portal web (alumnos):** [SETUP-GITHUB-PORTAL.md](../../.github/SETUP-GITHUB-PORTAL.md) · CLI: [GH-CLI-COMMANDS.md](../../.github/GH-CLI-COMMANDS.md)

---

## Validación final (todas las rutas)

1. `GET /health` o Swagger en cada API pública
2. Flujo Postman: [GUIA-ENDPOINTS.md](../GUIA-ENDPOINTS.md)
3. Limpieza: `Remove-AzureShopDemo.ps1` / `Remove-AwsShopDemo.ps1` para no dejar costos
