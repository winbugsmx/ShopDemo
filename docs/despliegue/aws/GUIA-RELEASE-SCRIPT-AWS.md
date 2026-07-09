# Guía — Release AWS con script PowerShell

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Enfoque** | **Script** — automatización con PowerShell |
| **Script** | [`scripts/aws/Deploy-AwsShopDemo.ps1`](../../../scripts/aws/Deploy-AwsShopDemo.ps1) |
| **Modos** | `ECS` · `EKS` · `All` |

**Preparación previa:** [PREPARACION-AMBIENTE-AWS.md](./PREPARACION-AMBIENTE-AWS.md)  
**Otras rutas equivalentes:** [CLI manual](./GUIA-RELEASE-CLI-AWS.md) · [Portal](./GUIA-RELEASE-PORTAL-AWS.md)

> El resultado final es el **mismo** que con CLI o Portal. El script **no hace build Docker**; los pasos de build están incluidos abajo.

---

## 1. Resumen de las tres rutas

| Ruta | Documento | Tiempo aprox. |
|---|---|---|
| **Script** (esta guía) | `Deploy-AwsShopDemo.ps1` | 2–4 h |
| **CLI** | [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md) | 10–16 h |
| **Portal** | [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md) | 12–20 h |

| Modo | Qué crea el script | Qué **tú** haces |
|---|---|---|
| **ECS** | VPC, SG, ECR, SSM, cluster Fargate, Postgres/Azurite, Cloud Map, 5 APIs + MCP con ALB | IAM, `.env.aws`, build/push ECR |
| **EKS** | ECR, cluster eksctl, nodegroup, Helm Ingress, `k8s/secrets.yaml`, kubectl apply | IAM, `.env.aws`, build/push ECR, perfil free-tier §7 |
| **All** | ECS + EKS | Todo lo anterior |

---

## 2. Paso 0 — Preparación (obligatorio)

### 2.1 Herramientas

| Herramienta | ECS | EKS |
|---|---|---|
| AWS CLI v2 | ✓ | ✓ |
| Docker Desktop | ✓ | ✓ |
| PowerShell 5.1+ | ✓ | ✓ |
| eksctl | — | ✓ |
| kubectl | — | ✓ |
| helm | — | ✓ (opcional) |

Verificación:

```powershell
aws --version
aws sts get-caller-identity
docker version
eksctl version    # solo EKS
kubectl version --client
```

### 2.2 IAM

```powershell
cd I:\Curso\ShopDemo\scripts\aws

# ECS
aws iam create-policy --policy-name ShopDemoLabECS `
  --policy-document file://iam-policy-shopdemo-lab-ecs.json `
  --description "ShopDemo lab ECS"

aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn arn:aws:iam::TU_ACCOUNT_ID:policy/ShopDemoLabECS

# EKS (si usarás -Mode EKS o All)
aws iam create-policy --policy-name ShopDemoLabEKS `
  --policy-document file://iam-policy-shopdemo-lab-eks.json `
  --description "ShopDemo lab EKS"

aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn arn:aws:iam::TU_ACCOUNT_ID:policy/ShopDemoLabEKS

# Push Docker a ECR
aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
```

Detalle: [PREPARACION-AMBIENTE-AWS.md §2](./PREPARACION-AMBIENTE-AWS.md#2-usuario-iam-y-políticas)

### 2.3 Azure Event Hubs (cross-cloud)

1. [portal.azure.com](https://portal.azure.com) → namespace Event Hubs
2. **Shared access policies** → **RootManageSharedAccessKey** → **Primary Connection String**
3. Guardar para el paso 3

### 2.4 Configurar `.env.aws`

```powershell
cd I:\Curso\ShopDemo\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws
```

| Variable | Valor lab |
|---|---|
| `AWS_REGION` | `us-east-2` |
| `EVENT_HUBS_CONNECTION_STRING` | Connection string Azure |
| `EVENT_HUB_NAME` | `shopdemo-events` |
| `LAB_PREFIX` | `shopdemo` |
| `ECS_CLUSTER_NAME` | `shopdemo-cluster` |
| `POSTGRES_USER` | `ShopDemo` |
| `POSTGRES_PASSWORD` | `ShopDemo123!` |
| `IMAGE_TAG` | `latest` |
| `EKS_CLUSTER_NAME` | `shopdemo-eks` |
| `EKS_NODE_TYPE` | **`t3.micro`** |
| `EKS_NODE_COUNT` | **`4`** |

### 2.5 Credenciales AWS CLI

```powershell
aws configure
# Region: us-east-2
aws sts get-caller-identity
```

---

## 3. Paso 1 — Build y push imágenes ECR (manual, antes o después del script)

El script **crea repos ECR** pero **no construye imágenes**. Ejecuta esto **antes** de que arranquen tasks/pods:

```powershell
$REGION = "us-east-2"
$TAG = "latest"
$ACCOUNT = (aws sts get-caller-identity --query Account --output text)
$ECR = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR

cd I:\Curso\ShopDemo

docker build -t shopdemo-catalog:$TAG -f ShopDemo.Catalog.Api/Dockerfile .
docker tag shopdemo-catalog:$TAG "$ECR/shopdemo-catalog:$TAG"
docker push "$ECR/shopdemo-catalog:$TAG"

docker build -t shopdemo-orders:$TAG -f ShopDemo.Orders.Api/Dockerfile .
docker tag shopdemo-orders:$TAG "$ECR/shopdemo-orders:$TAG"
docker push "$ECR/shopdemo-orders:$TAG"

docker build -t shopdemo-inventory:$TAG -f ShopDemo.Inventory.Api/Dockerfile .
docker tag shopdemo-inventory:$TAG "$ECR/shopdemo-inventory:$TAG"
docker push "$ECR/shopdemo-inventory:$TAG"

docker build -t shopdemo-analytics:$TAG -f ShopDemo.Analytics.Api/Dockerfile .
docker tag shopdemo-analytics:$TAG "$ECR/shopdemo-analytics:$TAG"
docker push "$ECR/shopdemo-analytics:$TAG"

docker build -t shopdemo-mcp:$TAG -f ShopDemo.McpGateway/Dockerfile .
docker tag shopdemo-mcp:$TAG "$ECR/shopdemo-mcp:$TAG"
docker push "$ECR/shopdemo-mcp:$TAG"
```

Verificar:

```powershell
aws ecr list-images --repository-name shopdemo-catalog --region us-east-2
```

---

## 4. Modo ECS — paso a paso

### 4.1 Ejecutar script

```powershell
cd I:\Curso\ShopDemo\scripts\aws
.\Deploy-AwsShopDemo.ps1 -Mode ECS
```

**Duración:** ~15–25 min.

### 4.2 Qué hace el script (orden interno)

| Paso script | Recursos creados |
|---|---|
| Paso 0 | Verifica AWS CLI + credenciales |
| Paso 1 | 5 repos ECR |
| Paso 2 | VPC `shopdemo-vpc`, 2 subnets públicas, IGW, route table |
| Paso 3 | SG `shopdemo-alb`, `shopdemo-apps`, `shopdemo-data` |
| Paso 4 | Cluster ECS `shopdemo-cluster`, rol `shopdemo-ecs-execution` |
| Paso 5 | SSM `/shopdemo/eh-connection` |
| Paso 6 | Tasks Fargate Postgres + Azurite; actualiza SSM pg-* y azurite-checkpoint con IPs reales; crea BDs |
| Paso 7 | Cloud Map namespace `shopdemo.local`, servicio `inventory` |
| Paso 8 | Task definitions Catalog, Inventory, Analytics, Orders, MCP |
| Paso 9 | 5 ALB + servicios ECS; Inventory con Cloud Map (sin ALB) |

Estado guardado en `scripts/aws/.deploy-state.json`.

### 4.3 Si las imágenes no estaban en ECR

1. Ejecutar **Paso 1** (build/push) de esta guía
2. **ECS** → cluster → cada servicio → **Update service** → **Force new deployment**

O desde CLI:

```powershell
aws ecs update-service --cluster shopdemo-cluster --service shopdemo-catalog --force-new-deployment --region us-east-2
# Repetir para orders, inventory, analytics, mcp
```

### 4.4 Validación ECS

```powershell
aws ecs list-services --cluster shopdemo-cluster --region us-east-2
aws elbv2 describe-load-balancers --region us-east-2 --query "LoadBalancers[?contains(LoadBalancerName,'shopdemo')].{Name:LoadBalancerName,DNS:DNSName}"
```

| URL | Ruta |
|---|---|
| Catalog Swagger | `http://<shopdemo-catalog-alb>/swagger/index.html` |
| Orders Swagger | `http://<shopdemo-orders-alb>/swagger/index.html` |
| Analytics | `http://<shopdemo-analytics-alb>/api/analytics/events` |
| MCP health | `http://<shopdemo-mcp-alb>/health` |
| Inventory (interno) | `http://inventory.shopdemo.local:8080` |

### 4.5 Teardown ECS

```powershell
cd I:\Curso\ShopDemo\scripts\aws
.\Remove-AwsShopDemo.ps1
```

---

## 5. Modo EKS — paso a paso

### 5.1 Ejecutar script

```powershell
cd I:\Curso\ShopDemo\scripts\aws
.\Deploy-AwsShopDemo.ps1 -Mode EKS
```

**Duración:** ~20–40 min.

### 5.2 Qué hace el script (orden interno)

| Paso | Acción |
|---|---|
| 1 | Verifica `eksctl`, `kubectl`, `helm` |
| 2 | Crea repos ECR (si no existen) |
| 3 | `eksctl create cluster` con `EKS_NODE_TYPE` y `EKS_NODE_COUNT` de `.env.aws` |
| 4 | Si cluster existe sin nodos → crea nodegroup `shopdemo-ng-v2` |
| 5 | `aws eks update-kubeconfig` |
| 6 | Helm: `ingress-nginx` (webhooks off, recursos reducidos) |
| 7 | Genera `k8s/secrets.yaml` (Event Hubs + Postgres in-cluster) |
| 8 | `kubectl apply` postgres, azurite, catalog, orders, inventory, analytics, mcp, ingress |
| 9 | `kubectl set image` con URIs ECR |
| 10 | Genera `scripts/aws/deploy-eks-report.json` |

### 5.3 Build/push ECR

Si no lo hiciste en §3, hazlo **antes** del paso 5.1 o fuerza redeploy:

```powershell
kubectl rollout restart deployment/shopdemo-catalog -n shopdemo
kubectl rollout restart deployment/shopdemo-orders -n shopdemo
kubectl rollout restart deployment/shopdemo-inventory -n shopdemo
```

### 5.4 Perfil `eks-free-tier-lab` (obligatorio en cuentas 8 vCPU)

El script despliega MCP, Ingress y Analytics que **no caben** en 4× `t3.micro`. Aplica **después** del script:

#### 5.4.1 Escalar nodegroup

```powershell
eksctl scale nodegroup `
  --cluster shopdemo-eks `
  --name shopdemo-ng-v2 `
  --nodes 4 --nodes-min 1 --nodes-max 4 `
  --region us-east-2
```

> Si el nodegroup se llamó `shopdemo-ng`, usa ese nombre o créalo con `-v2` si el anterior falló.

#### 5.4.2 Reducir CoreDNS

```powershell
kubectl scale deployment coredns -n kube-system --replicas=1
```

#### 5.4.3 Eliminar cargas no esenciales

```powershell
kubectl delete deployment shopdemo-mcp -n shopdemo --ignore-not-found
kubectl delete deployment ingress-nginx-controller -n ingress-nginx --ignore-not-found
kubectl scale deployment shopdemo-analytics -n shopdemo --replicas=0
kubectl delete hpa shopdemo-catalog-hpa -n shopdemo --ignore-not-found
```

#### 5.4.4 Re-aplicar manifiestos ajustados (repo)

```powershell
cd I:\Curso\ShopDemo
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/inventory/service.yaml
kubectl apply -f k8s/aws/catalog/deployment.yaml
kubectl apply -f k8s/aws/orders/deployment.yaml
kubectl apply -f k8s/aws/inventory/deployment.yaml
kubectl apply -f k8s/azurite/init-checkpoints-job.yaml
```

#### 5.4.5 Job Azurite checkpoints

```powershell
kubectl wait --for=condition=complete job/shopdemo-azurite-init-checkpoints -n shopdemo --timeout=120s
```

### 5.5 Validación EKS

```powershell
kubectl get pods -n shopdemo
kubectl get svc -n shopdemo shopdemo-catalog shopdemo-orders shopdemo-inventory
```

| API | URL (puerto **8080**) |
|---|---|
| Catalog | `http://<EXTERNAL-IP-catalog>:8080/swagger/index.html` |
| Orders | `http://<EXTERNAL-IP-orders>:8080/swagger/index.html` |
| Inventory | `http://<EXTERNAL-IP-inventory>:8080/swagger/index.html` |

Referencia validada: [`deploy-eks-free-tier-report.json`](../../../scripts/aws/deploy-eks-free-tier-report.json)

### 5.6 Teardown EKS

```powershell
cd I:\Curso\ShopDemo\scripts\aws
.\Remove-AwsShopDemo.ps1

# O manual:
eksctl delete cluster --name shopdemo-eks --region us-east-2
```

---

## 6. Modo All (ECS + EKS)

```powershell
cd I:\Curso\ShopDemo\scripts\aws
# Completar .env.aws con variables ECS y EKS
.\Deploy-AwsShopDemo.ps1 -Mode All
```

Orden recomendado:
1. Build/push ECR (§3)
2. Script `-Mode All`
3. Perfil free-tier EKS (§5.4)
4. Validar ECS (§4.4) y EKS (§5.5)

---

## 7. Solución de problemas

| Síntoma | Acción |
|---|---|
| `AccessDenied` ECS | Adjuntar `ShopDemoLabECS` |
| `AccessDenied` EKS | Adjuntar `ShopDemoLabEKS` |
| `not eligible for Free Tier` | `EKS_NODE_TYPE=t3.micro` en `.env.aws` |
| Nodegroup rollback | `eksctl delete nodegroup`; script usa `shopdemo-ng-v2` |
| Task stopped ECS | CloudWatch `/ecs/shopdemo-*`; verificar imagen ECR |
| Pods Pending EKS | Quitar MCP/Ingress/Analytics; máx. 16 pods |
| ImagePullBackOff | Push imágenes tag `latest` |
| Swagger 404 EKS | `ASPNETCORE_ENVIRONMENT=Development` en deployment |
| Timeout URL EKS | Usar **`:8080`** en Classic ELB |
| `Completa EVENT_HUBS...` | Pegar connection string Azure en `.env.aws` |

---

## 8. Documentación relacionada

| Tema | Enlace |
|---|---|
| Preparación IAM/cuotas | [PREPARACION-AMBIENTE-AWS.md](./PREPARACION-AMBIENTE-AWS.md) |
| CLI paso a paso | [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md) |
| Portal AWS | [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md) |
| Task definitions ECS | [ANEXO-TASK-DEFINITIONS-ECS.md](./ANEXO-TASK-DEFINITIONS-ECS.md) |
| Endpoints Postman | [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) |
