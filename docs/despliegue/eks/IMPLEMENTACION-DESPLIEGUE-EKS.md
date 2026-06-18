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
Cada paso: **Consola AWS** + **CLI**.

---

## Índice

1. [Variables](#1-variables)
2. [Paso 1 — Repositorios ECR](#2-paso-1--repositorios-ecr)
3. [Paso 2 — Crear cluster EKS](#3-paso-2--crear-cluster-eks)
4. [Paso 3 — Configurar kubectl](#4-paso-3--configurar-kubectl)
5. [Paso 4 — Build y push ECR](#5-paso-4--build-y-push-ecr)
6. [Paso 5 — EBS CSI + Ingress NGINX](#6-paso-5--ebs-csi--ingress-nginx)
7. [Paso 6 — Manifiestos con imágenes ECR](#7-paso-6--manifiestos-con-imágenes-ecr)
8. [Paso 7 — Desplegar ShopDemo](#8-paso-7--desplegar-shopdemo)
9. [Paso 8 — Testeo](#9-paso-8--testeo)
10. [Paso 9 — Limpieza](#10-paso-9--limpieza)

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

1. **Amazon ECR** → **Create repository** × 4: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`

### CLI

```bash
for repo in shopdemo-catalog shopdemo-orders shopdemo-inventory shopdemo-analytics; do
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

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t ${ECR}/shopdemo-catalog:v1 .
docker push ${ECR}/shopdemo-catalog:v1
# Repetir orders, inventory, analytics
```

---

## 6. Paso 5 — EBS CSI + Ingress NGINX

**EBS CSI:** necesario para PVC del StatefulSet Postgres.

### CLI

```bash
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --force

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### Consola

**EKS** → **Add-ons** → instalar **Amazon EBS CSI Driver**

---

## 7. Paso 6 — Manifiestos con imágenes ECR

Editar Deployments o crear variantes `deployment-eks.yaml`:

```yaml
image: <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/shopdemo-catalog:v1
imagePullPolicy: Always
```

---

## 8. Paso 7 — Desplegar ShopDemo

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl wait --for=condition=ready pod -l app=shopdemo-postgres -n shopdemo --timeout=300s
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/inventory/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/analytics/
kubectl apply -f k8s/ingress/
```

---

## 9. Paso 8 — Testeo

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
| Health pods | `kubectl describe pod -n shopdemo ...` |
| API Catalog | `/catalog/swagger` vía Ingress |
| E2E | [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) |

---

## 10. Paso 9 — Limpieza

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
