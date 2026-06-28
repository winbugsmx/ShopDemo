# Guía — Release AWS desde el Portal (Consola web)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Región lab** | `us-east-2` (Ohio) |
| **Enfoque** | **Portal** — consola web paso a paso |

**Preparación:** [PREPARACION-AMBIENTE-AWS.md](./PREPARACION-AMBIENTE-AWS.md)  
**Otras rutas equivalentes:** [Script](./GUIA-RELEASE-SCRIPT-AWS.md) · [CLI](./GUIA-RELEASE-CLI-AWS.md)

> El resultado final es el **mismo** que con el script o la CLI. Elige **una** ruta según tu preferencia de aprendizaje. Para EKS, la consola crea el cluster; los manifiestos Kubernetes se aplican con `kubectl` en tu PC (pasos incluidos abajo).

---

## 0. Usuario IAM y permisos

### 0.1 Crear políticas custom

1. Inicia sesión en [AWS Console](https://console.aws.amazon.com/)
2. Barra superior → región **`US East (Ohio) us-east-2`**
3. **IAM** → **Policies** → **Create policy** → pestaña **JSON**

**Política ECS** — pegar contenido de [`scripts/aws/iam-policy-shopdemo-lab-ecs.json`](../../../scripts/aws/iam-policy-shopdemo-lab-ecs.json):

| Campo | Valor |
|---|---|
| Nombre | `ShopDemoLabECS` |
| Descripción | ShopDemo lab ECS Fargate |

**Política EKS** — pegar [`scripts/aws/iam-policy-shopdemo-lab-eks.json`](../../../scripts/aws/iam-policy-shopdemo-lab-eks.json):

| Campo | Valor |
|---|---|
| Nombre | `ShopDemoLabEKS` |
| Descripción | ShopDemo lab EKS eksctl |

### 0.2 Adjuntar políticas al usuario

1. **IAM** → **Users** → tu usuario (ej. `valentinomx2026`)
2. **Permissions** → **Add permissions** → **Attach policies directly**
3. Seleccionar según modo:

| Modo release | Políticas mínimas |
|---|---|
| Solo ECS | `ShopDemoLabECS` + `AmazonEC2ContainerRegistryFullAccess` |
| Solo EKS | `ShopDemoLabEKS` + `AmazonEC2ContainerRegistryFullAccess` |
| ECS + EKS | `ShopDemoLabECS` + `ShopDemoLabEKS` + `AmazonEC2ContainerRegistryFullAccess` |

> **Límite:** máximo 10 políticas administradas por usuario. No adjuntes 8 políticas sueltas.

### 0.3 Access Key (CLI local)

1. **IAM** → **Users** → **Security credentials**
2. **Create access key** → **Command Line Interface (CLI)**
3. Guardar Access Key ID y Secret; configurar en PC con `aws configure`

---

## Parte A — Release ECS (Portal)

### A.1 Amazon ECR — repositorios e imágenes

#### A.1.1 Crear repositorios

1. **Amazon ECR** → **Repositories** → **Create repository**
2. Crear **5 repositorios** (tipo **Private**):

| Nombre |
|---|
| `shopdemo-catalog` |
| `shopdemo-orders` |
| `shopdemo-inventory` |
| `shopdemo-analytics` |
| `shopdemo-mcp` |

#### A.1.2 Build y push desde tu PC

En PowerShell (raíz del repo):

```powershell
$REGION = "us-east-2"
$ACCOUNT = (aws sts get-caller-identity --query Account --output text)
$ECR = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
$TAG = "latest"

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

3. Verificar en ECR: cada repo debe mostrar imagen con tag `latest`.

### A.2 VPC y red

1. **VPC** → **Create VPC** → **VPC and more**
2. Configuración:

| Campo | Valor |
|---|---|
| Name | `shopdemo-vpc` |
| IPv4 CIDR | `10.0.0.0/16` |
| AZs | 2 |
| Public subnets | 2 |
| NAT gateway | None (lab) |
| VPC endpoints | None |

3. Anotar **VPC ID** y **Subnet IDs** públicas.

### A.3 Security Groups

**VPC** → **Security Groups** → **Create security group** (3 grupos):

| Nombre | Inbound |
|---|---|
| `shopdemo-alb` | TCP 80 desde `0.0.0.0/0` |
| `shopdemo-apps` | TCP 8080 desde SG `shopdemo-alb` y desde sí mismo |
| `shopdemo-data` | TCP 5432 y 10000-10002 desde SG `shopdemo-apps` |

### A.4 Systems Manager — Parameter Store

**Systems Manager** → **Parameter Store** → **Create parameter**:

| Paso | Nombre | Tipo | Valor |
|---|---|---|---|
| 1 | `/shopdemo/eh-connection` | SecureString | Connection string Azure Event Hubs |
| 2–4 | `/shopdemo/pg-catalog`, `/shopdemo/pg-orders`, `/shopdemo/pg-inventory` | SecureString | **Temporal** — se actualizan en A.8 con IP real de Postgres |
| 5 | `/shopdemo/azurite-checkpoint` | SecureString | **Temporal** — se actualiza en A.8 con IP Azurite |

Valores temporales (placeholder hasta A.8):

```
Host=0.0.0.0;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123!
```

> Event Hubs: [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)

### A.5 Cloud Map (Service Discovery)

1. **Cloud Map** → **Create namespace**
2. **DNS private namespace**
3. **Namespace name:** `shopdemo.local`
4. **VPC:** `shopdemo-vpc`
5. **Create namespace** → esperar estado **ACTIVE**
6. Entrar al namespace → **Create service**
   - **Service name:** `inventory`
   - **DNS configuration:** Type **A**, TTL **10**
   - **Health check:** Custom → Failure threshold **1**
7. Anotar **Service ARN** (lo usarás al crear el servicio ECS Inventory)

### A.6 IAM — rol de ejecución ECS (Portal)

1. **IAM** → **Roles** → **Create role**
2. **Trusted entity:** AWS service → **Elastic Container Service** → **Elastic Container Service Task**
3. **Permissions:** adjuntar `AmazonECSTaskExecutionRolePolicy`
4. **Role name:** `shopdemo-ecs-execution`
5. Tras crear el rol → **Add permissions** → **Create inline policy** → JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["ssm:GetParameters", "ssm:GetParameter"],
    "Resource": "arn:aws:ssm:us-east-2:TU_ACCOUNT_ID:parameter/shopdemo/*"
  }]
}
```

6. **Policy name:** `ShopDemoSsmRead`

### A.7 ECS — cluster

1. **Amazon ECS** → **Clusters** → **Create cluster**
2. **Cluster name:** `shopdemo-cluster`
3. **Infrastructure:** **AWS Fargate (serverless)**
4. **Create**

### A.8 Task definitions (Portal)

**ECS** → **Task definitions** → **Create new task definition** → **Create new task definition with JSON**

Usa los JSON de [ANEXO-TASK-DEFINITIONS-ECS.md](./ANEXO-TASK-DEFINITIONS-ECS.md). Sustituye placeholders antes de pegar.

| Orden | Family | Anexo | Notas |
|---|---|---|---|
| 1 | `shopdemo-postgres` | §1 | Imagen `postgres:16-alpine`, puerto 5432 |
| 2 | `shopdemo-azurite` | §2 | Command Azurite blob |
| 3 | `shopdemo-catalog` | §3 | Secrets SSM |
| 4 | `shopdemo-inventory` | §4 | Secrets SSM + checkpoints |
| 5 | `shopdemo-analytics` | §6 | Sin connection string PG |
| 6 | `shopdemo-orders` | §5 | `InventoryApi__BaseUrl` → Cloud Map |
| 7 | `shopdemo-mcp` | §7 | **Último** — requiere DNS ALB Catalog y Analytics |

En cada task definition:
- **Launch type:** Fargate
- **Operating system:** Linux
- **Task execution role:** `shopdemo-ecs-execution`
- **Task size:** 0.5 vCPU, 1 GB

### A.9 Servicios ECS — Postgres y Azurite

**ECS** → cluster `shopdemo-cluster` → **Services** → **Create**

#### Postgres

| Campo | Valor |
|---|---|
| Compute options | Launch type → **Fargate** |
| Task definition | `shopdemo-postgres` |
| Service name | `shopdemo-postgres` |
| Desired tasks | 1 |
| VPC | `shopdemo-vpc` |
| Subnets | Ambas públicas |
| Security group | `shopdemo-data` |
| Public IP | **ON** |

#### Azurite

Igual que Postgres con task `shopdemo-azurite`, service `shopdemo-azurite`.

Esperar **Running** en ambos servicios.

### A.10 Obtener IPs y actualizar SSM

1. **ECS** → cluster → servicio `shopdemo-postgres` → pestaña **Tasks** → task **Running**
2. **Configuration** → **Network** → anotar **Private IP** → `<PG_IP>`
3. Repetir para `shopdemo-azurite` → `<AZ_IP>`
4. **Systems Manager** → **Parameter Store** → editar:

| Parámetro | Valor final |
|---|---|
| `/shopdemo/pg-catalog` | `Host=<PG_IP>;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123!` |
| `/shopdemo/pg-orders` | `Host=<PG_IP>;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123!` |
| `/shopdemo/pg-inventory` | `Host=<PG_IP>;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123!` |
| `/shopdemo/azurite-checkpoint` | Ver [ANEXO §8](./ANEXO-TASK-DEFINITIONS-ECS.md) con `<AZ_IP>` |

5. Crear bases de datos (desde PC con `psql` o task one-off):

```powershell
$env:PGPASSWORD = "ShopDemo123!"
psql -h <PG_IP> -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoCatalog";'
psql -h <PG_IP> -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoOrders";'
psql -h <PG_IP> -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoInventory";'
```

### A.11 Servicio Catalog con ALB

**ECS** → **Create service**:

| Campo | Valor |
|---|---|
| Task definition | `shopdemo-catalog` |
| Service name | `shopdemo-catalog` |
| Load balancer type | **Application Load Balancer** |
| Load balancer name | `shopdemo-catalog-alb` (crear nuevo) |
| Listener | HTTP :80 |
| Target group | `shopdemo-catalog-tg`, protocol HTTP, port **8080**, target type **IP** |
| Health check path | `/health` |
| VPC / subnets | Públicas |
| Security group apps | `shopdemo-apps` |
| Public IP | ON |

Anotar **DNS name** del ALB Catalog → `<ALB_CATALOG_DNS>`.

### A.12 Servicio Inventory + Cloud Map

**ECS** → **Create service**:

| Campo | Valor |
|---|---|
| Task definition | `shopdemo-inventory` |
| Service name | `shopdemo-inventory` |
| Load balancer | **None** |
| Service discovery | **Use existing** → namespace `shopdemo.local` → service `inventory` |
| Container name:port | `inventory-api:8080` |
| Subnets | Una subnet pública |
| Security group | `shopdemo-apps` |

Verificar en **Cloud Map** → service `inventory` → instancias registradas.

### A.13 Servicio Orders con ALB

Registrar task `shopdemo-orders` (Anexo §5) si no lo hiciste. Crear servicio igual que Catalog:

| ALB | Target group | Service |
|---|---|---|
| `shopdemo-orders-alb` | `shopdemo-orders-tg` | `shopdemo-orders` |

### A.14 Servicio Analytics con ALB

| ALB | Target group | Service |
|---|---|---|
| `shopdemo-analytics-alb` | `shopdemo-analytics-tg` | `shopdemo-analytics` |

Anotar DNS ALB Analytics → `<ALB_ANALYTICS_DNS>`.

### A.15 Servicio MCP con ALB

1. Editar JSON task `shopdemo-mcp` (Anexo §7):
   - `ShopDemo__CatalogApiBaseUrl` = `http://<ALB_CATALOG_DNS>`
   - `ShopDemo__AnalyticsApiBaseUrl` = `http://<ALB_ANALYTICS_DNS>`
   - `ShopDemo__InventoryApiBaseUrl` = `http://inventory.shopdemo.local:8080`
2. **Task definitions** → **Create new revision**
3. **Create service** con ALB `shopdemo-mcp-alb` / TG `shopdemo-mcp-tg`

### A.16 Validación ECS (Portal)

1. **ECS** → cluster → **Services** → los **7** servicios con **Running = 1**
2. **EC2** → **Load Balancers** → 5 ALB en estado **active**
3. **Target groups** → todos los targets **healthy** (esperar 2–5 min)
4. Navegador:

| URL |
|---|
| `http://<ALB_CATALOG_DNS>/swagger/index.html` |
| `http://<ALB_ORDERS_DNS>/swagger/index.html` |
| `http://<ALB_ANALYTICS_DNS>/api/analytics/events` |
| `http://<ALB_MCP_DNS>/health` |

### A.17 Logs y troubleshooting ECS

| Recurso | Dónde |
|---|---|
| Logs contenedor | **CloudWatch** → Log groups → `/ecs/shopdemo-*` |
| Task stopped | **ECS** → cluster → service → **Tasks** → **Stopped reason** |
| Target unhealthy | **EC2** → **Target Groups** → **Health checks** |

---

## Parte B — Release EKS (Portal + kubectl)

### B.1 Crear cluster EKS en Portal

1. **Amazon EKS** → **Clusters** → **Create cluster**
2. **Configure cluster:**

| Campo | Valor |
|---|---|
| Name | `shopdemo-eks` |
| Kubernetes version | Default (ej. 1.34) |
| Cluster IAM role | **Create new role** (EKS cluster role) |
| Cluster endpoint access | **Public** |

3. **Specify networking:** VPC por defecto o la creada por eksctl; subnets en al menos 2 AZ
4. **Configure logging:** opcional (CloudWatch)
5. **Create cluster** → esperar estado **Active** (~10–15 min)

**Alternativa CLI** (misma resultante):

```powershell
eksctl create cluster --name shopdemo-eks --region us-east-2 `
  --nodegroup-name shopdemo-ng-v2 --node-type t3.micro --nodes 4 --managed
```

### B.2 Crear node group en Portal

1. Cluster `shopdemo-eks` → **Compute** → **Add node group**
2. Configuración:

| Campo | Valor |
|---|---|
| Name | `shopdemo-ng-v2` |
| Node IAM role | Create new role |
| AMI type | Amazon Linux 2 |
| Capacity type | **On-Demand** |
| Instance type | **`t3.micro`** |
| Desired size | **4** |
| Minimum | **1** |
| Maximum | **4** |
| Subnets | Públicas o privadas según VPC |

3. **Create** → esperar **Active**

> **No uses `t3.medium`** en cuentas Free Tier.

### B.3 Configurar kubectl en tu PC

```powershell
aws eks update-kubeconfig --name shopdemo-eks --region us-east-2
kubectl get nodes
# Debe listar 4 nodos Ready
```

### B.4 ECR — imágenes

Repetir **A.1** completo (5 repos + docker build/push).

### B.5 Secrets Kubernetes

```powershell
cd I:\Curso\ShopDemo
copy k8s\secrets.example.yaml k8s\secrets.yaml
notepad k8s\secrets.yaml
```

Completar `EVENT_HUBS_CONNECTION_STRING` con connection string de Azure.

```powershell
kubectl apply -f k8s\namespace.yaml
kubectl apply -f k8s\secrets.yaml
```

Contenido de referencia (`k8s/secrets.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: shopdemo-secrets
  namespace: shopdemo
type: Opaque
stringData:
  POSTGRES_USER: ShopDemo
  POSTGRES_PASSWORD: ShopDemo123!
  EVENT_HUBS_CONNECTION_STRING: "<<<AZURE-EH-CONNECTION-STRING>>>"
  PG_CATALOG_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123!"
  PG_ORDERS_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123!"
  PG_INVENTORY_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123!"
  AZURITE_CHECKPOINT_CONN: "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://shopdemo-azurite:10000/devstoreaccount1;"
```

### B.6 Aplicar manifiestos Kubernetes

```powershell
cd I:\Curso\ShopDemo

$REGION = "us-east-2"
$ACCOUNT = (aws sts get-caller-identity --query Account --output text)
$ECR = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/deployment.yaml
kubectl apply -f k8s/azurite/service.yaml
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/inventory/

kubectl set image deployment/shopdemo-catalog catalog-api="${ECR}/shopdemo-catalog:latest" -n shopdemo
kubectl set image deployment/shopdemo-orders orders-api="${ECR}/shopdemo-orders:latest" -n shopdemo
kubectl set image deployment/shopdemo-inventory inventory-api="${ECR}/shopdemo-inventory:latest" -n shopdemo
```

### B.7 Job checkpoints Azurite

```powershell
kubectl apply -f k8s/azurite/init-checkpoints-job.yaml
kubectl wait --for=condition=complete job/shopdemo-azurite-init-checkpoints -n shopdemo --timeout=120s
```

### B.8 Perfil free-tier — liberar capacidad de pods

```powershell
kubectl scale deployment coredns -n kube-system --replicas=1
kubectl delete deployment shopdemo-mcp -n shopdemo --ignore-not-found
kubectl scale deployment shopdemo-analytics -n shopdemo --replicas=0
kubectl delete deployment ingress-nginx-controller -n ingress-nginx --ignore-not-found
kubectl delete hpa shopdemo-catalog-hpa -n shopdemo --ignore-not-found
```

### B.9 Verificar pods (Portal + CLI)

**CLI:**

```powershell
kubectl get pods -n shopdemo
kubectl get pods -n kube-system
```

Esperado en `shopdemo`: postgres, azurite, catalog, orders, inventory — todos **Running**.

**Portal:** **EKS** → cluster → **Resources** → **Workloads** (vista limitada; kubectl es la fuente de verdad).

### B.10 Load Balancers Classic en Portal

1. **EC2** → **Load Balancers**
2. Filtrar tipo **classic** o buscar tags `kubernetes.io/service-name`
3. Deberías ver **3** ELB para Catalog, Orders, Inventory
4. Copiar **DNS name** de cada uno

```powershell
kubectl get svc -n shopdemo shopdemo-catalog shopdemo-orders shopdemo-inventory
```

### B.11 Validación Swagger EKS

Navegador (puerto **8080** obligatorio):

| API | URL |
|---|---|
| Catalog | `http://<LB-dns-catalog>:8080/swagger/index.html` |
| Orders | `http://<LB-dns-orders>:8080/swagger/index.html` |
| Inventory | `http://<LB-dns-inventory>:8080/swagger/index.html` |

### B.12 Monitoreo EKS en Portal

| Qué revisar | Dónde |
|---|---|
| Pods | CLI: `kubectl get pods -n shopdemo` |
| Nodos | **EKS** → **Compute** o **EC2** → Instances |
| ELB | **EC2** → **Load Balancers** |
| CloudFormation stacks eksctl | **CloudFormation** → stacks `eksctl-shopdemo-eks-*` |
| Costos | **Billing** → **Free Tier** / **Cost Explorer** |

### B.13 Eliminar cluster EKS

**Opción CLI (recomendada):**

```powershell
eksctl delete cluster --name shopdemo-eks --region us-east-2
```

**Opción Portal:**

1. **EKS** → cluster → **Delete**
2. Confirmar eliminación de nodegroups y recursos asociados
3. **CloudFormation** → eliminar stacks huérfanos si quedan

---

## Parte C — Checklist Portal por servicio AWS

| Servicio AWS | ECS | EKS free-tier |
|---|---|---|
| IAM Policies | ShopDemoLabECS | ShopDemoLabEKS |
| ECR (5 repos) | ✓ | ✓ |
| VPC | ✓ | (eksctl crea VPC) |
| Security Groups | ✓ | (eksctl) |
| SSM Parameter Store | ✓ | — (secrets K8s) |
| Cloud Map | ✓ | — |
| ECS Cluster + Services | ✓ | — |
| ALB (Application) | ✓ (5) | — |
| EKS Cluster | — | ✓ |
| EC2 t3.micro nodes | — | ✓ (4) |
| Classic ELB (K8s LB) | — | ✓ (3) |
| CloudWatch Logs | ✓ | ✓ |

---

## Parte D — Azure Event Hubs (prerequisito cross-cloud)

**No es AWS Portal**, pero es obligatorio antes del release:

1. [portal.azure.com](https://portal.azure.com)
2. Namespace Event Hubs del curso
3. **Shared access policies** → **RootManageSharedAccessKey**
4. Copiar **Primary Connection String** → `.env.aws` o SSM / `k8s/secrets.yaml`

---

## Referencias

| Documento | Uso |
|---|---|
| [PREPARACION-AMBIENTE-AWS.md](./PREPARACION-AMBIENTE-AWS.md) | IAM, cuotas, herramientas |
| [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md) | Comandos exactos |
| [GUIA-RELEASE-SCRIPT-AWS.md](./GUIA-RELEASE-SCRIPT-AWS.md) | Script PowerShell |
| [GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md) | Contexto K8s |
