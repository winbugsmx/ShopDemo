# Manifiestos Kubernetes — ShopDemo

Despliegue de **4 APIs + MCP + PostgreSQL (StatefulSet) + Azurite + Ingress NGINX** en el namespace `shopdemo`.

Mismos YAML para **Minikube**, **AKS** y **EKS**; cambia el origen de las imágenes y algunos ajustes de plataforma.

## Estructura

```
k8s/
├── namespace.yaml
├── secrets.example.yaml      → copiar a secrets.yaml (no commitear)
├── postgres/                 → StatefulSet + Service headless
├── azurite/                  → Checkpoints Event Hubs + init-checkpoints job
├── catalog/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml              → HPA demo (Catalog)
├── orders/
├── inventory/
├── analytics/
├── mcp/                      → MCP Gateway (agentes IA)
└── ingress/                  → NGINX Ingress (shopdemo.local)
```

## Orden de aplicación

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
# Esperar postgres ready
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/inventory/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/analytics/
kubectl apply -f k8s/mcp/
kubectl apply -f k8s/catalog/hpa.yaml
kubectl apply -f k8s/ingress/
```

## Imágenes por entorno

Los manifiestos pueden referenciar ECR por defecto. Antes de aplicar en nube, apunta al registro correcto:

| Entorno | Registro | Ejemplo |
|---|---|---|
| Minikube | Imágenes locales (`minikube docker-env`) | `shopdemo-catalog:latest` |
| AKS | ACR | `acrshopdemolab01.azurecr.io/shopdemo-catalog:latest` |
| EKS | ECR | `<account>.dkr.ecr.<region>.amazonaws.com/shopdemo-catalog:latest` |

```bash
# AKS — tras push a ACR
kubectl set image deployment/shopdemo-catalog catalog=acrshopdemolab01.azurecr.io/shopdemo-catalog:latest -n shopdemo
```

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

1. Instalar Ingress NGINX con Helm (ver [GUIA-RELEASE-SCRIPT-AZURE §5.2](../docs/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md))
2. Anotar el Service del controller:

```yaml
service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
externalTrafficPolicy: Local
```

3. Agregar en **hosts**: `<IP-ingress> shopdemo.local`

URLs validadas (lab): [scripts/azure/deploy-aks-report.json](../scripts/azure/deploy-aks-report.json)

## EKS free-tier

Con 4× `t3.micro` (~16 pods) suele bastar solo Catalog + Orders + Inventory. Ver perfil post-script: [deploy-eks-free-tier-report.json](../scripts/aws/deploy-eks-free-tier-report.json)

## Documentación

| Entorno | Guía |
|---|---|
| Minikube (local) | [IMPLEMENTACION-KUBERNETES-LOCAL](../docs/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) |
| Elección de ruta | [GUIA-RELEASE-KUBERNETES](../docs/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |
| Azure AKS | [IMPLEMENTACION-DESPLIEGUE-AKS](../docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |
| Amazon EKS | [IMPLEMENTACION-DESPLIEGUE-EKS](../docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |
| Script Azure AKS | [scripts/azure/README.md](../scripts/azure/README.md) |
| Script AWS EKS | [scripts/aws/README.md](../scripts/aws/README.md) |
| CI/CD AKS/EKS | [.github/workflows/deploy-aks.yml](../.github/workflows/deploy-aks.yml) · [deploy-eks.yml](../.github/workflows/deploy-eks.yml) |
| MCP Gateway | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE](../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |
