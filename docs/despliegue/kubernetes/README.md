# Despliegue en Kubernetes — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Material para desplegar ShopDemo en **Kubernetes**: desarrollo local (Minikube) y nube (AKS / EKS).

**Guía de elección de ruta:** [GUIA-RELEASE-KUBERNETES.md](./GUIA-RELEASE-KUBERNETES.md) · **Alcance lab:** [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)

## Documentos

| Tema | Teoría | Requerimientos | Implementación |
|---|---|---|---|
| **Kubernetes local** | [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md) · [TEORIA-DOCKER-KUBERNETES-AOT.md](../../TEORIA-DOCKER-KUBERNETES-AOT.md) | [REQUERIMIENTOS-KUBERNETES.md](./REQUERIMIENTOS-KUBERNETES.md) | [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md) |
| **Azure AKS** | [TEORIA-AKS.md](../aks/TEORIA-AKS.md) | [REQUERIMIENTOS-DESPLIEGUE-AKS.md](../aks/REQUERIMIENTOS-DESPLIEGUE-AKS.md) | [IMPLEMENTACION-DESPLIEGUE-AKS.md](../aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |
| **Amazon EKS** | [TEORIA-EKS.md](../eks/TEORIA-EKS.md) | [REQUERIMIENTOS-DESPLIEGUE-EKS.md](../eks/REQUERIMIENTOS-DESPLIEGUE-EKS.md) | [IMPLEMENTACION-DESPLIEGUE-EKS.md](../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |

## Manifiestos en el repositorio

Carpeta [`k8s/`](../../k8s/) — recursos **compartidos** + deployments por cloud (`local/`, `azure/`, `aws/`).

Guía operativa: [k8s/README.md](../../k8s/README.md)

## Reportes de release (lab)

| Entorno | Archivo |
|---|---|
| Azure AKS (completo: 5 APIs + MCP + Ingress) | [scripts/azure/deploy-aks-report.json](../../scripts/azure/deploy-aks-report.json) |
| AWS EKS free-tier (3 APIs + LB) | [scripts/aws/deploy-eks-free-tier-report.json](../../scripts/aws/deploy-eks-free-tier-report.json) |
| AWS EKS completo | [scripts/aws/deploy-eks-report.json](../../scripts/aws/deploy-eks-report.json) |

## Scripts de automatización

| Plataforma | Modo | Script |
|---|---|---|
| Azure | ACA / AKS / All | [Deploy-AzureShopDemo.ps1](../../scripts/azure/Deploy-AzureShopDemo.ps1) |
| AWS | ECS / EKS / All | [Deploy-AwsShopDemo.ps1](../../scripts/aws/Deploy-AwsShopDemo.ps1) |

## Relación con otros despliegues

| Enfoque | Documentación | Uso |
|---|---|---|
| Docker Compose | Por API en `*/docker-compose.yml` | Dev rápido por servicio |
| Azure Container Apps | [despliegue/azure/](../azure/) | Serverless sin K8s |
| AWS ECS Fargate | [despliegue/aws/](../aws/) | Contenedores sin K8s |
| **Kubernetes** | Esta carpeta | Orquestación K8s estándar |
