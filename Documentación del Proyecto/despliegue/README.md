# Despliegue de contenedores ShopDemo — Azure y AWS

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Índice general del curso:** [README.md](../../README.md)  
**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md)

Material del curso para llevar los microservicios Docker a la nube con enfoque **práctico y básico**.

## Documentación 3 capas (despliegue)

Estructura según [GUIA-ESTRUCTURA-DOCUMENTACION.md](../GUIA-ESTRUCTURA-DOCUMENTACION.md): **A** negocio · **B** técnica · **C** pedagogía.

| Módulo | Índice README |
|---|---|
| Azure ACA | [azure/README.md](./azure/README.md) |
| AWS ECS | [aws/README.md](./aws/README.md) |
| Kubernetes local | [kubernetes/README.md](./kubernetes/README.md) |
| AKS | [aks/README.md](./aks/README.md) |
| EKS | [eks/README.md](./eks/README.md) |

Cada módulo incluye: `REQUERIMIENTOS-*` · `HISTORIAS-USUARIO-*` · `ANEXO-ESPECIFICACION-TECNICA-*` · `ANEXO-HISTORIAS-TECNICAS-*` · `ANEXO-PEDAGOGIA-*`

## Alcance del lab (2 días · pocas horas)

**[ALCANCE-LAB-RELEASE.md](./ALCANCE-LAB-RELEASE.md)** — qué servicios son obligatorios, rutas por tiempo y cuándo usar script vs Portal vs CLI.

## Guías de release separadas

Cada plataforma ofrece **tres enfoques equivalentes** (Script, CLI, Portal). El script es el camino más rápido para el lab.

### Azure

| Documento | Uso |
|---|---|
| [PREPARACION-AMBIENTE-AZURE.md](./azure/PREPARACION-AMBIENTE-AZURE.md) | Suscripción, cuotas, permisos |
| [GUIA-RELEASE-SCRIPT-AZURE.md](./azure/GUIA-RELEASE-SCRIPT-AZURE.md) | **Recomendada** — `Deploy-AzureShopDemo.ps1` (ACA + AKS) |
| [GUIA-RELEASE-CLI-AZURE.md](./azure/GUIA-RELEASE-CLI-AZURE.md) | ACA (A.1–A.14) + AKS (B.1–B.11) con `az` |
| [GUIA-RELEASE-PORTAL-AZURE.md](./azure/GUIA-RELEASE-PORTAL-AZURE.md) | Portal visual ACA + AKS |
| [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) | Índice + nombres + troubleshooting |

**Release AKS validado:** [Source/scripts/azure/deploy-aks-report.json](../../Source/scripts/azure/deploy-aks-report.json)

### AWS

| Documento | Uso |
|---|---|
| [PREPARACION-AMBIENTE-AWS.md](./aws/PREPARACION-AMBIENTE-AWS.md) | IAM, cuotas, región |
| [GUIA-RELEASE-SCRIPT-AWS.md](./aws/GUIA-RELEASE-SCRIPT-AWS.md) | **Recomendada** — `Deploy-AwsShopDemo.ps1` + IAM |
| [GUIA-RELEASE-CLI-AWS.md](./aws/GUIA-RELEASE-CLI-AWS.md) | ECS (A.0–A.19) + EKS (B.0–B.14) con `aws` |
| [GUIA-RELEASE-PORTAL-AWS.md](./aws/GUIA-RELEASE-PORTAL-AWS.md) | Consola visual + IAM |
| [IMPLEMENTACION-DESPLIEGUE-AWS.md](./aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) | Índice + IAM + troubleshooting |
| [ANEXO-TASK-DEFINITIONS-ECS.md](./aws/ANEXO-TASK-DEFINITIONS-ECS.md) | JSON task definitions (ruta manual) |

**Release EKS validado (free-tier):** [Source/scripts/aws/deploy-eks-free-tier-report.json](../../Source/scripts/aws/deploy-eks-free-tier-report.json)

### Kubernetes

| Documento | Uso |
|---|---|
| [GUIA-RELEASE-KUBERNETES.md](./kubernetes/GUIA-RELEASE-KUBERNETES.md) | Minikube vs AKS vs EKS — qué elegir |

## Scripts PowerShell de release (automatización)

| Plataforma | Carpeta | Guía | Modos | CI/CD (merge `main`) |
|---|---|---|---|---|
| **Azure** | [Source/scripts/azure/](../../Source/scripts/azure/) | [README](../../Source/scripts/azure/README.md) | `ACA` · `AKS` · `All` | [deploy-azure.yml](../../.github/workflows/deploy-azure.yml) · [deploy-aks.yml](../../.github/workflows/deploy-aks.yml) |
| **AWS** | [Source/scripts/aws/](../../Source/scripts/aws/) | [README](../../Source/scripts/aws/README.md) | `ECS` · `EKS` · `All` | [deploy-aws.yml](../../.github/workflows/deploy-aws.yml) · [deploy-eks.yml](../../.github/workflows/deploy-eks.yml) |

**Checklist secrets:** [.github/SECRETS-CHECKLIST.md](../../.github/SECRETS-CHECKLIST.md) · **Setup:** [.github/SETUP-GITHUB.md](../../.github/SETUP-GITHUB.md)

**No incluyen build Docker** — tras ejecutar el script, publica imágenes con GitHub Actions o build manual.

| Paso | Azure (`Source/scripts/azure/`) | AWS (`Source/scripts/aws/`) |
|---|---|---|
| 1 | `copy .env.azure.example .env.azure` | `copy .env.aws.example .env.aws` |
| 2 | `az login` | `aws configure` |
| 3 | `.\Deploy-AzureShopDemo.ps1 -Mode ACA` | `.\Deploy-AwsShopDemo.ps1 -Mode ECS` |
| 4 | Push ACR ([deploy-azure.yml](../../.github/workflows/deploy-azure.yml)) | Push ECR ([deploy-aws.yml](../../.github/workflows/deploy-aws.yml)) |
| 5 | `.\Remove-AzureShopDemo.ps1` | `.\Remove-AwsShopDemo.ps1` |

Detalle en [GUIA-RELEASE-SCRIPT-AZURE](./azure/GUIA-RELEASE-SCRIPT-AZURE.md) y [GUIA-RELEASE-SCRIPT-AWS](./aws/GUIA-RELEASE-SCRIPT-AWS.md).

## Decisiones del curso

| Tema | Azure | AWS |
|---|---|---|
| Cómputo | **Azure Container Apps** | **Amazon ECS Fargate** |
| Registro de imágenes | **Azure Container Registry (ACR)** | **Amazon ECR** |
| APIs desplegadas | Catalog, Orders, Inventory, Analytics, **MCP Gateway** | Igual |
| AppHost Aspire | Solo desarrollo local — **no se despliega** | Igual |
| PostgreSQL | Contenedor (ACI / ECS) | Contenedor (ECS + EFS) |
| Checkpoints Event Hubs | **Storage Account** (`shopdemochecklab01`) en ACA · **Azurite** en AKS/K8s | **Azurite** (`shopdemo-azurite`) en ECS |
| Mensajería | Azure Event Hubs (existente en código) | Conexión cross-cloud a Event Hubs |
| Automatización | CLI + Portal + **scripts PowerShell** + GitHub Actions | CLI + Consola + **scripts PowerShell** + GitHub Actions |

## Documentos por plataforma

### Tópicos de Estudio

Material de teoría general (no sustituye la práctica del lab). Índice: [Documentación de Estudio del Curso/README.md](../../Documentación de Estudio del Curso/README.md)

| # | Tópico | Enlace |
|---|---|---|
| 01 | Patrones de diseño | [01-patrones-diseno.md](../../Documentación de Estudio del Curso/01-patrones-diseno.md) |
| 02 | Arquitecturas de software | [02-arquitecturas-software.md](../../Documentación de Estudio del Curso/02-arquitecturas-software.md) |
| 03 | DDD | [03-ddd-domain-driven-design.md](../../Documentación de Estudio del Curso/03-ddd-domain-driven-design.md) |
| 04 | Microservicios y comunicación | [04-microservicios-comunicacion.md](../../Documentación de Estudio del Curso/04-microservicios-comunicacion.md) |
| 05 | Servicios Azure | [05-servicios-azure.md](../../Documentación de Estudio del Curso/05-servicios-azure.md) |
| 06 | Servicios AWS | [06-servicios-aws.md](../../Documentación de Estudio del Curso/06-servicios-aws.md) |
| 07 | Contenedores y Docker | [07-contenedores-docker.md](../../Documentación de Estudio del Curso/07-contenedores-docker.md) |
| 08 | Kubernetes | [08-kubernetes-orquestacion.md](../../Documentación de Estudio del Curso/08-kubernetes-orquestacion.md) |
| 09 | CI/CD y DevOps | [09-ci-cd-devops.md](../../Documentación de Estudio del Curso/09-ci-cd-devops.md) |
| 10 | Observabilidad | [10-observabilidad.md](../../Documentación de Estudio del Curso/10-observabilidad.md) |
| 11 | Resiliencia | [11-resiliencia.md](../../Documentación de Estudio del Curso/11-resiliencia.md) |
| 12 | Integración IA y MCP | [12-integracion-ia-mcp.md](../../Documentación de Estudio del Curso/12-integracion-ia-mcp.md) |
| 13 | Síntesis | [13-sintesis-integracion.md](../../Documentación de Estudio del Curso/13-sintesis-integracion.md) |

### Kubernetes (Minikube / AKS / EKS)

| Documento | Contenido |
|---|---|
| [kubernetes/README.md](./kubernetes/README.md) | Índice K8s |
| [kubernetes/TEORIA-KUBERNETES-OPERACIONES.md](./kubernetes/TEORIA-KUBERNETES-OPERACIONES.md) | kubectl, Secrets, Probes, HPA, Ingress |
| [kubernetes/REQUERIMIENTOS-KUBERNETES.md](./kubernetes/REQUERIMIENTOS-KUBERNETES.md) | Justificación Minikube |
| [kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md](./kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) | Minikube — compartidos `k8s/` + `k8s/local/` |
| [aks/](./aks/) | AKS: Helm Ingress, Secrets, Probes, HPA |
| [eks/](./eks/) | EKS: Helm Ingress, Secrets, Probes, HPA |

### Observabilidad y resiliencia

| Tema | Teoría | Requerimientos | Azure | AWS |
|---|---|---|---|---|
| **Observabilidad** | [observabilidad/TEORIA-OBSERVABILIDAD.md](../observabilidad/TEORIA-OBSERVABILIDAD.md) | [REQUERIMIENTOS-OBSERVABILIDAD.md](../observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) | [ACA + AKS](../observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) | [ECS + EKS](../observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) |
| **Resiliencia** | [resiliencia/TEORIA-RESILIENCIA.md](../resiliencia/TEORIA-RESILIENCIA.md) | [REQUERIMIENTOS-RESILIENCIA.md](../resiliencia/REQUERIMIENTOS-RESILIENCIA.md) | [ACA + AKS](../resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md) | [ECS + EKS](../resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md) |
| **Integración IA** | [integracion-ia/TEORIA-INTEGRACION-IA.md](../integracion-ia/TEORIA-INTEGRACION-IA.md) | [REQUERIMIENTOS-INTEGRACION-IA.md](../integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) | [ACA + AKS](../integracion-ia/azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md) | [ECS + EKS](../integracion-ia/aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md) |
| **MCP Gateway (despliegue)** | — | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](../integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |

### Azure (Container Apps)

| Documento | Contenido |
|---|---|
| [PREPARACION-AMBIENTE-AZURE.md](./azure/PREPARACION-AMBIENTE-AZURE.md) | Preparación suscripción y cuotas |
| [TEORIA-CONTENEDORES-AZURE.md](./azure/TEORIA-CONTENEDORES-AZURE.md) | ACR, Container Apps, secretos, networking |
| [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) | Justificación y alcance |
| [GUIA-RELEASE-SCRIPT-AZURE.md](./azure/GUIA-RELEASE-SCRIPT-AZURE.md) | Script PowerShell (recomendado) |
| [GUIA-RELEASE-CLI-AZURE.md](./azure/GUIA-RELEASE-CLI-AZURE.md) | Azure CLI manual |
| [GUIA-RELEASE-PORTAL-AZURE.md](./azure/GUIA-RELEASE-PORTAL-AZURE.md) | Portal visual |

### AWS

| Documento | Contenido |
|---|---|
| [PREPARACION-AMBIENTE-AWS.md](./aws/PREPARACION-AMBIENTE-AWS.md) | Preparación IAM y cuotas |
| [TEORIA-CONTENEDORES-AWS.md](./aws/TEORIA-CONTENEDORES-AWS.md) | ECR, ECS Fargate, Cloud Map |
| [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) | Justificación y alcance |
| [GUIA-RELEASE-SCRIPT-AWS.md](./aws/GUIA-RELEASE-SCRIPT-AWS.md) | Script PowerShell + IAM (recomendado) |
| [GUIA-RELEASE-CLI-AWS.md](./aws/GUIA-RELEASE-CLI-AWS.md) | AWS CLI manual |
| [GUIA-RELEASE-PORTAL-AWS.md](./aws/GUIA-RELEASE-PORTAL-AWS.md) | Consola visual |

## Spec-driven development (etapa 15)

Para que el agente de IA (Cursor o Claude Code) siga las mismas especificaciones del curso al desplegar en Azure o AWS:

| Documento | Contenido |
|---|---|
| [spec-driven/README.md](../../spec-driven/README.md) | Índice spec-driven |
| [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](../../spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) | Activar plantillas Cursor / Claude Code |
| [specs/06-deploy-azure](../../spec-driven/specs/06-deploy-azure/SPEC.md) | SPEC despliegue Azure |
| [specs/07-deploy-aws](../../spec-driven/specs/07-deploy-aws/SPEC.md) | SPEC despliegue AWS |

## Prerequisitos comunes

- Imágenes Docker funcionando en local (`docker compose` por servicio)
- Cuenta en Azure y/o AWS con permisos para crear recursos
- Azure CLI (`az`) y/o AWS CLI (`aws`) instalados
- Event Hubs configurado: [INTEGRACION-AZURE-EVENT-HUBS.md](../INTEGRACION-AZURE-EVENT-HUBS.md)

## Estructura Docker en el repo

| Servicio | Dockerfile | docker-compose |
|---|---|---|
| Catalog | `Source/Catalog/ShopDemo.Catalog.Api/Dockerfile` | `Source/Catalog/ShopDemo.Catalog.Api/docker-compose.yml` |
| Orders | `Source/Orders/ShopDemo.Orders.Api/Dockerfile` | `Source/Orders/ShopDemo.Orders.Api/docker-compose.yml` |
| Inventory | `Source/Inventory/ShopDemo.Inventory.Api/Dockerfile` | `Source/Inventory/ShopDemo.Inventory.Api/docker-compose.yml` |
| Analytics | `Source/Aspire/ShopDemo.Analytics.Api/Dockerfile` | `Source/Aspire/ShopDemo.Analytics.Api/docker-compose.yml` |
| MCP Gateway | `Source/AI/ShopDemo.Mcp.Api/Dockerfile` | `Source/AI/ShopDemo.Mcp.Api/docker-compose.yml` |

## Problemas frecuentes (release validado)

| Síntoma | Plataforma | Solución |
|---|---|---|
| Swagger 404 en AKS/EKS | K8s | `ASPNETCORE_ENVIRONMENT=Development` |
| Swagger timeout ELB | EKS | URL con puerto **`:8080`** |
| Analytics CrashLoopBackOff | AKS | Consumer group `analytics-service` en Event Hubs |
| Ingress timeout | AKS | Health probe `/healthz` en Service Ingress NGINX |
| Script falla en Ingress | AKS | Helm manual — ver GUIA-RELEASE-SCRIPT-AZURE §5.2 |
| Pods Pending | EKS free-tier | Perfil reducido — ver deploy-eks-free-tier-report.json |
