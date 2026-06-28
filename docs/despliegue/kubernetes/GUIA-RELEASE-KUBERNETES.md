# Guía — Release en Kubernetes (Minikube, AKS, EKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Objetivo** | Elegir **una** ruta K8s según tiempo y nube |

**Alcance del lab:** [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)

---

## ¿Qué ruta elegir?

| Ruta | Tiempo | Costo cloud | Cuándo |
|---|---|---|---|
| **Minikube local** | ~4 h | $0 | Entender manifiestos `k8s/` sin pagar nube |
| **AKS** (Azure) | +2–3 h tras ACA | Sí | Ya hiciste release ACA con script |
| **EKS** (AWS) | +2–3 h tras ECS | Sí | Ya hiciste release ECS con script |

**No es obligatorio** hacer Minikube + AKS + EKS en el mismo alumno. Para un lab de 2 días con pocas horas: **ACA o ECS con script** + opcional **Minikube**.

---

## Manifiestos comunes (`k8s/`)

| Carpeta | Contenido |
|---|---|
| `k8s/postgres/` | PostgreSQL |
| `k8s/azurite/` | Checkpoints Event Hubs |
| `k8s/catalog/`, `orders/`, `inventory/`, `analytics/` | APIs |
| `k8s/mcp/` | MCP Gateway |
| `k8s/ingress/` | Ingress NGINX |
| `k8s/secrets.example.yaml` | Plantilla → copiar a `secrets.yaml` (no commitear) |

Checkpoints en K8s: **Azurite** (no Storage Account de Azure).

---

## Ruta 1 — Minikube (recomendada para aprender K8s)

**Guía detallada:** [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md)

### Resumen en 6 pasos

```bash
minikube start --cpus 4 --memory 8192
minikube addons enable ingress

eval $(minikube docker-env)   # Linux/macOS
# Windows PowerShell: minikube docker-env | Invoke-Expression

cd I:\Curso\ShopDemo
# build 5 imágenes con tag local (ver IMPLEMENTACION-KUBERNETES-LOCAL §5)

copy k8s\secrets.example.yaml k8s\secrets.yaml
# Editar connection strings Event Hubs y PostgreSQL

kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl apply -f k8s/catalog/ -f k8s/inventory/ -f k8s/orders/ -f k8s/analytics/ -f k8s/mcp/
kubectl apply -f k8s/ingress/

minikube ip   # o minikube tunnel para LoadBalancer
```

**Teoría:** [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md)

---

## Ruta 2 — AKS (Azure)

**Prerequisito:** Event Hubs + imágenes en ACR.

**Preparación:** [PREPARACION-AMBIENTE-AZURE.md](../azure/PREPARACION-AMBIENTE-AZURE.md)

### Tres enfoques equivalentes

| Enfoque | Guía |
|---|---|
| Script | [GUIA-RELEASE-SCRIPT-AZURE.md](../azure/GUIA-RELEASE-SCRIPT-AZURE.md) §5 |
| CLI | [GUIA-RELEASE-CLI-AZURE.md](../azure/GUIA-RELEASE-CLI-AZURE.md) Parte B |
| Portal | [GUIA-RELEASE-PORTAL-AZURE.md](../azure/GUIA-RELEASE-PORTAL-AZURE.md) Parte B |

### Pasos clave post-provisionamiento

1. Consumer groups EH: `analytics-service`, `inventory-service`
2. Helm Ingress con `health-probe-request-path=/healthz`
3. `kubectl apply` manifiestos + imágenes ACR
4. Archivo `hosts`: `<IP-Ingress> shopdemo.local`
5. Swagger: `http://shopdemo.local/catalog/swagger/index.html`

Reporte lab: [deploy-aks-report.json](../../../scripts/azure/deploy-aks-report.json)

### CI/CD — merge a `main`

Tras [SETUP-GITHUB.md](../../../.github/SETUP-GITHUB.md) y [SECRETS-CHECKLIST.md](../../../.github/SECRETS-CHECKLIST.md):

| Workflow | Acción |
|---|---|
| [deploy-aks.yml](../../../.github/workflows/deploy-aks.yml) | build ACR → `kubectl set image` (5 servicios) |
| Cambios en `k8s/**` | apply automático de manifiestos |

Primer run manual: `sync_secrets` + `apply_manifests` (+ `apply_infra` si cluster nuevo).

### Servicios Azure que toca AKS

| Servicio | ¿Script? |
|---|---|
| ACR (imágenes) | Sí |
| AKS cluster | Sí (`-Mode AKS`) |
| Event Hubs | Sí o previo |
| Ingress NGINX (Helm) | Manual si script falla |
| **Container Apps** | No en modo solo AKS |

---

## Ruta 3 — EKS (AWS)

**Prerequisito:** Imágenes en ECR + Event Hubs connection string + política IAM `ShopDemoLabEKS`.

**Preparación:** [PREPARACION-AMBIENTE-AWS.md](../aws/PREPARACION-AMBIENTE-AWS.md)

### Con script (recomendado)

```powershell
cd I:\Curso\ShopDemo\scripts\aws
copy .env.aws.example .env.aws
# EKS_NODE_TYPE=t3.micro, EKS_NODE_COUNT=4, AWS_REGION=us-east-2

.\Deploy-AwsShopDemo.ps1 -Mode EKS
# eksctl + Ingress + k8s/secrets.yaml + kubectl apply base
```

### Perfil free-tier lab (post-script)

En cuentas con límite **8 vCPU** y **4 pods/nodo** en `t3.micro`, aplicar ajustes manuales:

```powershell
eksctl scale nodegroup --cluster shopdemo-eks --name shopdemo-ng-v2 --nodes 4 --region us-east-2
kubectl scale deployment coredns -n kube-system --replicas=1
kubectl delete deployment shopdemo-mcp -n shopdemo --ignore-not-found
kubectl scale deployment shopdemo-analytics -n shopdemo --replicas=0
kubectl delete deployment ingress-nginx-controller -n ingress-nginx --ignore-not-found
kubectl apply -f k8s/azurite/init-checkpoints-job.yaml
```

Swagger público (LoadBalancer, puerto **8080**):

```powershell
kubectl get svc -n shopdemo shopdemo-catalog shopdemo-orders shopdemo-inventory
# http://<EXTERNAL-IP>:8080/swagger/index.html
```

**Guías detalladas:**

| Documento | Contenido |
|---|---|
| [GUIA-RELEASE-SCRIPT-AWS.md](../aws/GUIA-RELEASE-SCRIPT-AWS.md) | Script + perfil free-tier |
| [GUIA-RELEASE-CLI-AWS.md](../aws/GUIA-RELEASE-CLI-AWS.md) | CLI paso a paso |
| [IMPLEMENTACION-DESPLIEGUE-EKS.md](../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) | Arquitectura EKS |

### CI/CD — merge a `main`

| Workflow | Acción |
|---|---|
| [deploy-eks.yml](../../../.github/workflows/deploy-eks.yml) | build ECR → `kubectl set image` (5 servicios) |
| Cambios en `k8s/**` | apply automático de manifiestos |

Configuración: [SETUP-GITHUB.md](../../../.github/SETUP-GITHUB.md)

### Servicios AWS que toca EKS

| Servicio | ¿Script? |
|---|---|
| ECR | Sí |
| EKS cluster (eksctl) | Sí (`-Mode EKS`) |
| Classic ELB (K8s LoadBalancer) | Automático (Catalog/Orders/Inventory) |
| **ECS / ALB / Cloud Map** | No necesario en modo solo EKS |

---

## Comparación rápida

| Tema | Minikube | AKS | EKS |
|---|---|---|---|
| Ingress | Addon NGINX | Helm NGINX | Helm NGINX |
| Imágenes | Build local | ACR | ECR |
| Secretos | `k8s/secrets.yaml` | Igual | Igual |
| Checkpoints | Azurite in-cluster | Azurite | Azurite |
| Costo | Gratis | Pago por cluster | Pago por cluster |

---

## Validación

1. `kubectl get pods` — todos `Running`
2. Ingress / `minikube tunnel` — Swagger en cada API
3. Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md)

---

## Limpieza

| Ruta | Comando |
|---|---|
| Minikube | `minikube delete` |
| AKS | `.\Remove-AzureShopDemo.ps1` o borrar RG |
| EKS | `.\Remove-AwsShopDemo.ps1` o `eksctl delete cluster` |
