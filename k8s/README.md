# Manifiestos Kubernetes — ShopDemo

Despliegue de **4 APIs + MCP + PostgreSQL (StatefulSet) + Azurite + Ingress NGINX** en el namespace `shopdemo`.

Recursos **compartidos** (todos los entornos) + **deployments por cloud** (imagen del registro correcto).

## Estructura

```
k8s/
├── namespace.yaml
├── secrets.example.yaml      → copiar a secrets.yaml (no commitear)
├── postgres/                 → StatefulSet + Service headless
├── azurite/                  → Checkpoints Event Hubs + init-checkpoints job
├── catalog/
│   ├── service.yaml
│   └── hpa.yaml              → HPA demo (Catalog)
├── orders/service.yaml
├── inventory/service.yaml
├── analytics/service.yaml
├── mcp/service.yaml
├── ingress/                  → NGINX Ingress (shopdemo.local)
├── azure/                    → Deployments AKS (ACR)
│   ├── catalog/deployment.yaml
│   ├── orders/deployment.yaml
│   ├── inventory/deployment.yaml
│   ├── analytics/deployment.yaml
│   └── mcp/deployment.yaml
├── aws/                      → Deployments EKS (ECR)
│   └── … (misma estructura)
└── local/                    → Deployments Minikube (imagen local)
    └── … (misma estructura)
```

## Orden de aplicación

### Minikube (local)

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/inventory/service.yaml
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/analytics/service.yaml
kubectl apply -f k8s/mcp/service.yaml
kubectl apply -f k8s/local/catalog/deployment.yaml
kubectl apply -f k8s/local/inventory/deployment.yaml
kubectl apply -f k8s/local/orders/deployment.yaml
kubectl apply -f k8s/local/analytics/deployment.yaml
kubectl apply -f k8s/local/mcp/deployment.yaml
kubectl apply -f k8s/catalog/hpa.yaml
kubectl apply -f k8s/ingress/
```

O con el script del repo:

```bash
APPLY_INFRA=true bash .github/scripts/apply-k8s-manifests.sh k8s local
```

### AKS / EKS (CI/CD o manual)

| Cloud | Script | Registro de imágenes |
|---|---|---|
| **AKS** | `apply-k8s-manifests.sh k8s azure` | `acrshopdemolab01.azurecr.io/shopdemo-*:latest` |
| **EKS** | `apply-k8s-manifests.sh k8s aws` | `905221885508.dkr.ecr.us-east-2.amazonaws.com/shopdemo-*:latest` |

Workflows: [deploy-aks.yml](../.github/workflows/deploy-aks.yml) · [deploy-eks.yml](../.github/workflows/deploy-eks.yml)

> **Importante:** no mezclar deployments de `k8s/azure/` en AKS con los de `k8s/aws/` — el apply en AKS con manifiestos ECR provoca `ImagePullBackOff`.

## Imágenes por entorno

| Entorno | Carpeta | Ejemplo imagen Catalog |
|---|---|---|
| Minikube | `k8s/local/` | `shopdemo-catalog:latest` |
| AKS | `k8s/azure/` | `acrshopdemolab01.azurecr.io/shopdemo-catalog:latest` |
| EKS | `k8s/aws/` | `905221885508.dkr.ecr.us-east-2.amazonaws.com/shopdemo-catalog:latest` |

Tras el primer `apply`, CI/CD actualiza tags con `kubectl set image` (build → push registry → rollout).

## Swagger y variables en nube

| Variable | Valor en lab | Motivo |
|---|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Development` | Expone Swagger en release |
| Puerto Service `LoadBalancer` | `8080` (target) | Classic ELB AWS: usar `:8080/swagger` en URL externa |

## Event Hubs (AKS/EKS)

| Requisito | Detalle |
|---|---|
| Consumer groups | `analytics-service`, `inventory-service` en el Event Hub `shopdemo-events` |
| Checkpoints | Azurite in-cluster (`k8s/azurite/`) |
| Job init | `k8s/azurite/init-checkpoints-job.yaml` crea contenedores de checkpoint |

```bash
# Azure — consumer groups (si Analytics falla en CrashLoopBackOff)
az eventhubs eventhub consumer-group create --resource-group rg-shopdemo-lab \
  --namespace-name <namespace-eh> --eventhub-name shopdemo-events --name analytics-service
```

## Ingress en Azure AKS

Si el Load Balancer del Ingress no responde externamente:

1. Instalar Ingress NGINX con Helm (ver [GUIA-RELEASE-SCRIPT-AZURE §5.2](../Documentación_Del_Proyecto/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md))
2. Anotar el Service del controller:

```yaml
service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
externalTrafficPolicy: Local
```

3. Agregar en **hosts**: `<IP-ingress> shopdemo.local`

URLs validadas (lab): [Source/scripts/azure/deploy-aks-report.json](../Source/scripts/azure/deploy-aks-report.json)

## EKS free-tier

Con 4× `t3.micro` (~16 pods) suele bastar solo Catalog + Orders + Inventory. Ver perfil post-script: [deploy-eks-free-tier-report.json](../Source/scripts/aws/deploy-eks-free-tier-report.json)

## Documentación

| Entorno | Guía |
|---|---|
| Minikube (local) | [IMPLEMENTACION-KUBERNETES-LOCAL](../Documentación_Del_Proyecto/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) |
| Elección de ruta | [GUIA-RELEASE-KUBERNETES](../Documentación_Del_Proyecto/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |
| Azure AKS | [IMPLEMENTACION-DESPLIEGUE-AKS](../Documentación_Del_Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |
| Amazon EKS | [IMPLEMENTACION-DESPLIEGUE-EKS](../Documentación_Del_Proyecto/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |
| Script Azure AKS | [Source/scripts/azure/README.md](../Source/scripts/azure/README.md) |
| Script AWS EKS | [Source/scripts/aws/README.md](../Source/scripts/aws/README.md) |
| CI/CD AKS/EKS | [.github/workflows/deploy-aks.yml](../.github/workflows/deploy-aks.yml) · [deploy-eks.yml](../.github/workflows/deploy-eks.yml) |
| MCP Gateway | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE](../Documentación_Del_Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |

## Tópicos de Estudio

| # | Tópico | Enlace |
|---|---|---|
| 07 | Contenedores y Docker | [07-contenedores-docker.md](../Documentación_De_Estudio_Del_Curso/07-contenedores-docker.md) |
| 08 | Kubernetes | [08-kubernetes-orquestacion.md](../Documentación_De_Estudio_Del_Curso/08-kubernetes-orquestacion.md) |

Índice completo: [Documentación_De_Estudio_Del_Curso/README.md](../Documentación_De_Estudio_Del_Curso/README.md)
