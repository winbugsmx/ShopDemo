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

Material del curso para llevar los microservicios Docker a la nube con enfoque **práctico y básico**.

## Decisiones del curso

| Tema | Azure | AWS |
|---|---|---|
| Cómputo | **Azure Container Apps** | **Amazon ECS Fargate** |
| Registro de imágenes | **Azure Container Registry (ACR)** | **Amazon ECR** |
| APIs desplegadas | Catalog, Orders, Inventory, Analytics | Igual |
| AppHost Aspire | Solo desarrollo local — **no se despliega** | Igual |
| PostgreSQL | Contenedor (ACI / ECS) | Contenedor (ECS + EFS) |
| Mensajería | Azure Event Hubs (existente en código) | Conexión cross-cloud a Event Hubs |
| Automatización | CLI + Portal + GitHub Actions básico | CLI + Consola + GitHub Actions básico |

## Documentos por plataforma

### Kubernetes (Minikube / AKS / EKS)

| Documento | Contenido |
|---|---|
| [kubernetes/README.md](./kubernetes/README.md) | Índice K8s |
| [kubernetes/TEORIA-KUBERNETES-OPERACIONES.md](./kubernetes/TEORIA-KUBERNETES-OPERACIONES.md) | kubectl, Secrets, Probes, HPA, Ingress |
| [kubernetes/REQUERIMIENTOS-KUBERNETES.md](./kubernetes/REQUERIMIENTOS-KUBERNETES.md) | Justificación Minikube |
| [kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md](./kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) | Minikube + manifiestos `k8s/` |
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
| [TEORIA-CONTENEDORES-AZURE.md](./azure/TEORIA-CONTENEDORES-AZURE.md) | ACR, Container Apps, secretos, networking |
| [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) | Justificación y alcance |
| [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) | Paso a paso **Portal + CLI** |

### AWS

| Documento | Contenido |
|---|---|
| [TEORIA-CONTENEDORES-AWS.md](./aws/TEORIA-CONTENEDORES-AWS.md) | ECR, ECS Fargate, Cloud Map, EFS |
| [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) | Justificación y alcance |
| [IMPLEMENTACION-DESPLIEGUE-AWS.md](./aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) | Paso a paso **Consola + CLI** |

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
| Catalog | `Catalog/ShopDemo.Catalog.Api/Dockerfile` | `Catalog/ShopDemo.Catalog.Api/docker-compose.yml` |
| Orders | `Orders/ShopDemo.Orders.Api/Dockerfile` | `Orders/ShopDemo.Orders.Api/docker-compose.yml` |
| Inventory | `Inventory/ShopDemo.Inventory.Api/Dockerfile` | `Inventory/ShopDemo.Inventory.Api/docker-compose.yml` |
| Analytics | `Aspire/ShopDemo.Analytics.Api/Dockerfile` | `Aspire/ShopDemo.Analytics.Api/docker-compose.yml` |
