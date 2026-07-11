# Implementación — Despliegue en Amazon EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisito:** [IMPLEMENTACION-KUBERNETES-LOCAL.md](../kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md)  
**Preparación IAM/cuotas:** [PREPARACION-AMBIENTE-AWS.md](../aws/PREPARACION-AMBIENTE-AWS.md)  
**Guías actualizadas (recomendadas):** [GUIA-RELEASE-SCRIPT-AWS.md](../aws/GUIA-RELEASE-SCRIPT-AWS.md) · [GUIA-RELEASE-CLI-AWS.md](../aws/GUIA-RELEASE-CLI-AWS.md) · [GUIA-RELEASE-PORTAL-AWS.md](../aws/GUIA-RELEASE-PORTAL-AWS.md)  
**Perfil lab validado:** `eks-free-tier-lab` — 4× `t3.micro`, LoadBalancer en Source/Catalog, Source/Orders, Source/Inventory, Swagger en **:8080** (ver guía Script §6)  
**Script automatizado:** [Source/scripts/aws/README.md](../../../Source/scripts/aws/README.md) (`-Mode EKS` genera `k8s/secrets.yaml`)  
**CI/CD:** [deploy-eks.yml](../../../.github/workflows/deploy-eks.yml) · [SETUP-GITHUB.md](../../../.github/SETUP-GITHUB.md)

---

## Índice

0. [Script PowerShell (`-Mode EKS`)](#0-script-powershell--mode-eks)
1. [Variables](#1-variables)
2. [Paso 1 — Repositorios ECR](#2-paso-1--repositorios-ecr)
3. [Paso 2 — Crear cluster EKS](#3-paso-2--crear-cluster-eks)
4. [Paso 3 — Configurar kubectl](#4-paso-3--configurar-kubectl)
5. [Paso 4 — Build y push ECR](#5-paso-4--build-y-push-ecr)
6. [Paso 5 — EBS CSI + Ingress NGINX](#6-paso-5--ebs-csi--ingress-nginx)
7. [Paso 6 — Manifiestos con imágenes ECR](#7-paso-6--manifiestos-con-imágenes-ecr)
8. [Paso 7 — Desplegar ShopDemo](#8-paso-7--desplegar-shopdemo)
9. [Paso 8 — Secrets, Probes y HPA](#9-paso-8--secrets-probes-y-hpa)
10. [Paso 9 — Testeo](#10-paso-9--testeo)
11. [Paso 10 — Limpieza](#11-paso-10--limpieza)

---

## 0. Script PowerShell (`-Mode EKS`)

Provisiona ECR, cluster EKS (eksctl), Ingress y `k8s/secrets.yaml`:

```powershell
cd I:\Curso\ShopDemo\Source\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws   # EVENT_HUBS_CONNECTION_STRING (Azure), EKS_CLUSTER_NAME

aws configure
.\Deploy-AwsShopDemo.ps1 -Mode EKS
```

| Qué hace el script | Qué debes hacer tú después |
|---|---|
| Repositorios ECR (5) | `docker push` a ECR |
| `eksctl create cluster` + kubeconfig | Aplicar compartidos + **`k8s/aws/`** (imágenes ECR ya en YAML) |
| Helm Ingress NGINX | `apply-k8s-manifests.sh k8s aws` o apply manual — ver [k8s/README.md](../../../k8s/README.md) |
| Genera `k8s/secrets.yaml` (Event Hubs cross-cloud) | No commitear secrets |

Guía: [Source/scripts/aws/README.md](../../../Source/scripts/aws/README.md).  
ECS + EKS: `.\Deploy-AwsShopDemo.ps1 -Mode All`.

Los pasos manuales (§2–§11) complementan el script para aprendizaje o despliegue 100 % manual.

---

## 0b. CI/CD GitHub Actions (`deploy-eks.yml`)

Configura [SETUP-GITHUB.md](../../../.github/SETUP-GITHUB.md) (environment `aws-eks` + secrets).

| Evento | Acción |
|---|---|
| Merge a `main` (apps) | build → push ECR → `kubectl set image` |
| Merge a `main` (`k8s/**`) | apply compartidos + **`k8s/aws/`** (`apply-k8s-manifests.sh k8s aws`) |
| Manual | `sync_secrets`, `apply_manifests`, `apply_infra` |

Checklist: [SECRETS-CHECKLIST.md](../../../.github/SECRETS-CHECKLIST.md)

---

## 1. Variables

```bash
export AWS_REGION=us-east-1
export CLUSTER_NAME=shopdemo-eks
export ECR_PREFIX=shopdemo
```

---

## 2. Paso 1 — Repositorios ECR

### Consola AWS

1. **Amazon ECR** → **Create repository** × 5: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp`

### CLI

```bash
for repo in shopdemo-catalog shopdemo-orders shopdemo-inventory shopdemo-analytics shopdemo-mcp; do
  aws ecr create-repository --repository-name $repo --region $AWS_REGION
done
```

---

## 3. Paso 2 — Crear cluster EKS

### Consola AWS

1. **Amazon EKS** → **Create cluster**
2. Name: `shopdemo-eks`, Kubernetes version reciente
3. **Cluster IAM role** (crear si falta)
4. **Specify VPC** — default o dedicada
5. Crear **node group**: 1 nodo `t3.medium`
6. Esperar estado **Active**

### CLI (eksctl — recomendado)

```bash
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --nodegroup-name shopdemo-ng \
  --node-type t3.medium \
  --nodes 1 \
  --managed
```

**Explicación:** `eksctl` crea VPC, roles IAM y node group automáticamente.

---

## 4. Paso 3 — Configurar kubectl

### Consola

EKS → cluster → **Compute** → **Connect** → pasos para `update-kubeconfig`

### CLI

```bash
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
kubectl get nodes
```

---

## 5. Paso 4 — Build y push ECR

```bash
cd I:\Curso\ShopDemo
$ACCOUNT = aws sts get-caller-identity --query Account --output text
$ECR = "$ACCOUNT.dkr.ecr.$env:AWS_REGION.amazonaws.com"

aws ecr get-login-password --region $env:AWS_REGION | docker login --username AWS --password-stdin $ECR

docker build -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile -t ${ECR}/shopdemo-catalog:v1 .
docker push ${ECR}/shopdemo-catalog:v1

docker build -f Source/Orders/ShopDemo.Orders.Api/Dockerfile -t ${ECR}/shopdemo-orders:v1 .
docker push ${ECR}/shopdemo-orders:v1

docker build -f Source/Inventory/ShopDemo.Inventory.Api/Dockerfile -t ${ECR}/shopdemo-inventory:v1 .
docker push ${ECR}/shopdemo-inventory:v1

docker build -f Source/Aspire/ShopDemo.Analytics.Api/Dockerfile -t ${ECR}/shopdemo-analytics:v1 .
docker push ${ECR}/shopdemo-analytics:v1

docker build -f Source/AI/ShopDemo.Mcp.Api/Dockerfile -t ${ECR}/shopdemo-mcp:v1 .
docker push ${ECR}/shopdemo-mcp:v1
```

---

## 6. Paso 5 — EBS CSI + Ingress NGINX (Helm)

**EBS CSI:** necesario para PVC del StatefulSet Postgres.

### CLI

```bash
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --force

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

**Explicación:** En EKS el Ingress se instala con **Helm** (igual que AKS). Minikube usa addon en su lugar.

### Consola

**EKS** → **Add-ons** → instalar **Amazon EBS CSI Driver**

---

## 7. Paso 6 — Manifiestos EKS (`k8s/aws/`)

Los deployments EKS referencian **ECR** directamente. **No uses `k8s/azure/`** en un cluster AWS.

| Carpeta | Contenido |
|---|---|
| `k8s/aws/catalog/deployment.yaml`, … | Imagen `905221885508.dkr.ecr.us-east-2.amazonaws.com/shopdemo-*:latest` |
| `k8s/catalog/service.yaml`, … | Services compartidos |

Verifica tag tras push:

```bash
grep image: k8s/aws/catalog/deployment.yaml
```

---

## 8. Paso 7 — Desplegar ShopDemo

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl wait --for=condition=ready pod -l app=shopdemo-postgres -n shopdemo --timeout=300s

kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/inventory/service.yaml
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/analytics/service.yaml
kubectl apply -f k8s/mcp/service.yaml

kubectl apply -f k8s/aws/catalog/deployment.yaml
kubectl apply -f k8s/aws/inventory/deployment.yaml
kubectl apply -f k8s/aws/orders/deployment.yaml
kubectl apply -f k8s/aws/analytics/deployment.yaml
kubectl apply -f k8s/aws/mcp/deployment.yaml

kubectl apply -f k8s/catalog/hpa.yaml
kubectl apply -f k8s/ingress/

kubectl get pods -n shopdemo
kubectl get ingress -n shopdemo
```

**Alternativa:** `APPLY_INFRA=true bash .github/scripts/apply-k8s-manifests.sh k8s aws`

---

## 9. Paso 8 — Secrets, Probes y HPA

### 9.1 Kubernetes Secrets

| Paso | Acción |
|---|---|
| 1 | `copy k8s\secrets.example.yaml k8s\secrets.yaml` |
| 2 | Completar connection strings (PG interno + Event Hubs Azure) |
| 3 | `kubectl apply -f k8s/secrets.yaml` |

> Event Hubs sigue en Azure aunque el cómputo esté en AWS; el cluster EKS necesita salida HTTPS a internet.

### 9.2 Liveness y Readiness

```bash
kubectl describe pod -n shopdemo -l app=shopdemo-catalog
curl http://<ingress-host>/catalog/health
```

Los manifiestos usan `httpGet` a `/health` (readiness) y `/alive` (liveness) en puerto 8080.

### 9.3 Autoscaling (HPA)

Verificar metrics-server (EKS 1.29+ suele traerlo):

```bash
kubectl get deployment metrics-server -n kube-system
# Si no existe:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl apply -f k8s/catalog/hpa.yaml
kubectl get hpa -n shopdemo -w
```

---

## 10. Paso 9 — Testeo

```bash
kubectl get ingress -n shopdemo
kubectl get pods -n shopdemo
```

Obtener hostname del Ingress (NLB/ELB en AWS):

```bash
kubectl get svc -n ingress-nginx
```

| Prueba | Referencia |
|---|---|
| Health pods | `kubectl describe pod -n shopdemo ...` — probes Success |
| HPA Catalog | `kubectl get hpa -n shopdemo` |
| API Catalog | `/catalog/swagger` vía Ingress |
| E2E | [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) |

---

## 11. Paso 10 — Limpieza

### Consola

EKS → Delete cluster; ECR → delete repositories

### CLI

```bash
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION
```

---

## Errores comunes

Ver [TEORIA-EKS.md](./TEORIA-EKS.md) §4.

---

## Referencias

- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) (ECR compartido con ECS)
