# Implementación — Despliegue de contenedores en AWS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Plataforma:** ECS Fargate + ECR + ALB + Cloud Map  
**Versión:** 1.0

> Cada paso incluye **Consola AWS** y **AWS CLI** como dos caminos equivalentes.

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 8)  
**Qué integrar:** `Dockerfile` y `docker-compose.yml` de cada API; parámetros SSM/Secrets Manager — **sin código C# nuevo**.

---

## Índice

1. [Prerequisitos](#1-prerequisitos)
2. [Variables del laboratorio](#2-variables-del-laboratorio)
3. [Paso 1 — Configurar AWS CLI](#3-paso-1--configurar-aws-cli)
4. [Paso 2 — VPC y subnets](#4-paso-2--vpc-y-subnets)
5. [Paso 3 — Security Groups](#5-paso-3--security-groups)
6. [Paso 4 — Repositorios ECR](#6-paso-4--repositorios-ecr)
7. [Paso 5 — Build y push de imágenes](#7-paso-5--build-y-push-de-imágenes)
8. [Paso 6 — Secrets (Parameter Store)](#8-paso-6--secrets-parameter-store)
9. [Paso 7 — ECS Cluster](#9-paso-7--ecs-cluster)
10. [Paso 8 — PostgreSQL en ECS](#10-paso-8--postgresql-en-ecs)
11. [Paso 9 — Azurite en ECS](#11-paso-9--azurite-en-ecs)
12. [Paso 10 — Cloud Map (Inventory)](#12-paso-10--cloud-map-inventory)
13. [Paso 11 — ALB + Catalog](#13-paso-11--alb--catalog)
14. [Paso 12 — Desplegar Inventory (interno)](#14-paso-12--desplegar-inventory-interno)
15. [Paso 13 — Desplegar Orders](#15-paso-13--desplegar-orders)
16. [Paso 14 — Desplegar Analytics](#16-paso-14--desplegar-analytics)
17. [Paso 15 — Probar el flujo](#17-paso-15--probar-el-flujo)
18. [Paso 16 — GitHub Actions](#18-paso-16--github-actions)
19. [Paso 17 — Limpieza](#19-paso-17--limpieza)
20. [Solución de problemas](#20-solución-de-problemas)

---

## 1. Prerequisitos

- Cuenta AWS con permisos administrador (lab)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Docker Desktop
- Repositorio ShopDemo clonado
- Event Hubs en Azure configurado (connection string)

---

## 2. Variables del laboratorio

```bash
# PowerShell / Bash
$AWS_REGION = "us-east-1"
$CLUSTER = "shopdemo-cluster"
$VPC_NAME = "shopdemo-vpc"
$PG_PASSWORD = "ShopDemo123!"
$EH_CONN = "<EVENT_HUBS_CONNECTION_STRING>"
```

```bash
export AWS_REGION=us-east-1
export CLUSTER=shopdemo-cluster
export PG_PASSWORD=ShopDemo123!
export EH_CONN="<EVENT_HUBS_CONNECTION_STRING>"
```

---

## 3. Paso 1 — Configurar AWS CLI

**Objetivo:** Autenticar la CLI contra tu cuenta.

### Enfoque A — Consola AWS (usuario IAM)

1. **IAM** → **Users** → tu usuario → **Security credentials**
2. **Create access key** → CLI
3. Guardar Access Key ID y Secret

### Enfoque B — AWS CLI

```bash
aws configure
# AWS Access Key ID: ...
# AWS Secret Access Key: ...
# Default region: us-east-1
# Default output: json

aws sts get-caller-identity
```

---

## 4. Paso 2 — VPC y subnets

**Objetivo:** Red donde correrán las tareas Fargate y los ALB.

### Enfoque A — Consola AWS

1. **VPC** → **Create VPC**
2. **VPC and more** (asistente):
   - Name: `shopdemo-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - 2 AZ, 2 subnets públicas, Internet Gateway: **Sí**
   - NAT Gateway: **No** (lab económico; tareas en subnet pública)
3. **Create VPC**

Anotar IDs: `vpc-id`, `subnet-a`, `subnet-b`.

### Enfoque B — AWS CLI

```bash
# Crear VPC
$VPC_ID = aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=shopdemo-vpc

# Internet Gateway
$IGW = aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID

# Subnets públicas (ejemplo us-east-1a / 1b)
$SUBNET_A = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
  --availability-zone ${AWS_REGION}a --query Subnet.SubnetId --output text
$SUBNET_B = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
  --availability-zone ${AWS_REGION}b --query Subnet.SubnetId --output text

aws ec2 modify-subnet-attribute --subnet-id $SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_B --map-public-ip-on-launch
```

---

## 5. Paso 3 — Security Groups

**Objetivo:** Reglas mínimas entre ALB, APIs, PostgreSQL y salida a internet.

### Enfoque A — Consola AWS

1. **EC2** → **Security Groups** → **Create**

**SG `sg-alb-shopdemo`:**
- Inbound: HTTP 80 desde `0.0.0.0/0`
- Outbound: All

**SG `sg-apps-shopdemo`:**
- Inbound: TCP 8080 desde `sg-alb-shopdemo`
- Inbound: TCP 8080 desde `sg-apps-shopdemo` (comunicación Orders→Inventory)
- Inbound: TCP 5432 desde `sg-apps-shopdemo` (hacia Postgres)
- Inbound: TCP 10000 desde `sg-apps-shopdemo` (hacia Azurite)
- Outbound: All (Event Hubs Azure por HTTPS)

**SG `sg-data-shopdemo`:**
- Inbound: 5432 y 10000 solo desde `sg-apps-shopdemo`

### Enfoque B — AWS CLI

```bash
$SG_ALB = aws ec2 create-security-group --group-name sg-alb-shopdemo \
  --description "ALB ShopDemo" --vpc-id $VPC_ID --query GroupId --output text

$SG_APPS = aws ec2 create-security-group --group-name sg-apps-shopdemo \
  --description "ECS apps ShopDemo" --vpc-id $VPC_ID --query GroupId --output text

$SG_DATA = aws ec2 create-security-group --group-name sg-data-shopdemo \
  --description "Postgres Azurite" --vpc-id $VPC_ID --query GroupId --output text

# ALB: HTTP desde internet
aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0

# Apps: 8080 desde ALB
aws ec2 authorize-security-group-ingress --group-id $SG_APPS --protocol tcp --port 8080 --source-group $SG_ALB

# Apps: tráfico entre apps
aws ec2 authorize-security-group-ingress --group-id $SG_APPS --protocol tcp --port 8080 --source-group $SG_APPS

# Data: Postgres y Azurite desde apps
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 5432 --source-group $SG_APPS
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 10000 --source-group $SG_APPS
```

---

## 6. Paso 4 — Repositorios ECR

**Objetivo:** Cuatro repositorios para las imágenes de las APIs.

### Enfoque A — Consola AWS

1. **Amazon ECR** → **Create repository**
2. Crear: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`
3. Visibility: **Private**

### Enfoque B — AWS CLI

```bash
foreach ($repo in @("shopdemo-catalog","shopdemo-orders","shopdemo-inventory","shopdemo-analytics")) {
  aws ecr create-repository --repository-name $repo --region $AWS_REGION
}
```

```bash
# Bash
for repo in shopdemo-catalog shopdemo-orders shopdemo-inventory shopdemo-analytics; do
  aws ecr create-repository --repository-name $repo --region $AWS_REGION
done
```

**URI del registry:**

```bash
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$ECR_URI = "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
echo $ECR_URI
```

---

## 7. Paso 5 — Build y push de imágenes

**Objetivo:** Subir las mismas imágenes Docker del repo a ECR.

### Enfoque A — Consola AWS

1. ECR → repositorio `shopdemo-catalog` → **View push commands**
2. Seguir los 4 comandos que muestra la consola (login, build, tag, push)
3. Repetir por cada repositorio

### Enfoque B — AWS CLI + Docker

```bash
cd I:\Curso\ShopDemo

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $ECR_URI/shopdemo-catalog:latest .
docker push $ECR_URI/shopdemo-catalog:latest

docker build -f Orders/ShopDemo.Orders.Api/Dockerfile -t $ECR_URI/shopdemo-orders:latest .
docker push $ECR_URI/shopdemo-orders:latest

docker build -f Inventory/ShopDemo.Inventory.Api/Dockerfile -t $ECR_URI/shopdemo-inventory:latest .
docker push $ECR_URI/shopdemo-inventory:latest

docker build -f Aspire/ShopDemo.Analytics.Api/Dockerfile -t $ECR_URI/shopdemo-analytics:latest .
docker push $ECR_URI/shopdemo-analytics:latest
```

**Verificación:**

```bash
aws ecr list-images --repository-name shopdemo-catalog --region $AWS_REGION
```

---

## 8. Paso 6 — Secrets (Parameter Store)

**Objetivo:** Guardar connection strings fuera de las task definitions en texto plano.

### Enfoque A — Consola AWS

1. **Systems Manager** → **Parameter Store** → **Create parameter**
2. Crear parámetros **SecureString**:

| Nombre | Valor |
|---|---|
| `/shopdemo/eh-connection` | Connection string Event Hubs |
| `/shopdemo/pg-catalog` | Connection string Catalog |
| `/shopdemo/pg-orders` | Connection string Orders |
| `/shopdemo/pg-inventory` | Connection string Inventory |
| `/shopdemo/azurite-checkpoint` | Connection string Azurite |

### Enfoque B — AWS CLI

```bash
aws ssm put-parameter --name /shopdemo/eh-connection --value "$EH_CONN" --type SecureString --overwrite

# Tras desplegar Postgres, actualizar con host real:
$PG_HOST = "<DNS_O_IP_POSTGRES>"
$PG_CATALOG = "Host=$PG_HOST;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=$PG_PASSWORD"
aws ssm put-parameter --name /shopdemo/pg-catalog --value "$PG_CATALOG" --type SecureString --overwrite
```

Repetir para orders, inventory y azurite.

---

## 9. Paso 7 — ECS Cluster

**Objetivo:** Cluster Fargate vacío donde registraremos servicios.

### Enfoque A — Consola AWS

1. **ECS** → **Clusters** → **Create cluster**
2. Name: `shopdemo-cluster`
3. Infrastructure: **AWS Fargate (serverless)**
4. **Create**

### Enfoque B — AWS CLI

```bash
aws ecs create-cluster --cluster-name $CLUSTER --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1
```

---

## 10. Paso 8 — PostgreSQL en ECS

**Objetivo:** Contenedor PostgreSQL accesible desde las APIs.

### Enfoque A — Consola AWS

1. **ECS** → Cluster → **Task definitions** → **Create**
2. Family: `shopdemo-postgres`
3. Launch type: Fargate, CPU 512, Memory 1024
4. Container:
   - Name: `postgres`
   - Image: `postgres:16-alpine`
   - Port: 5432
   - Env: `POSTGRES_USER=ShopDemo`, `POSTGRES_PASSWORD=<password>`
5. **Create service**:
   - Service name: `shopdemo-postgres`
   - Desired tasks: 1
   - Subnets públicas, SG `sg-data-shopdemo`
   - Sin ALB

6. Tras arrancar, obtener IP privada de la tarea y crear las 3 bases con cliente SQL.

### Enfoque B — AWS CLI (task definition JSON resumida)

Crear archivo `ecs-postgres-task.json`:

```json
{
  "family": "shopdemo-postgres",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "postgres",
      "image": "postgres:16-alpine",
      "essential": true,
      "portMappings": [{ "containerPort": 5432, "protocol": "tcp" }],
      "environment": [
        { "name": "POSTGRES_USER", "value": "ShopDemo" },
        { "name": "POSTGRES_PASSWORD", "value": "ShopDemo123!" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-postgres",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```bash
aws logs create-log-group --log-group-name /ecs/shopdemo-postgres
aws ecs register-task-definition --cli-input-json file://ecs-postgres-task.json

aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-postgres \
  --task-definition shopdemo-postgres \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A],securityGroups=[$SG_DATA],assignPublicIp=ENABLED}"
```

Obtener IP de la tarea:

```bash
aws ecs list-tasks --cluster $CLUSTER --service-name shopdemo-postgres
aws ecs describe-tasks --cluster $CLUSTER --tasks <TASK_ARN> \
  --query "tasks[0].attachments[0].details[?name=='privateIPv4Address'].value" --output text
```

---

## 11. Paso 9 — Azurite en ECS

**Objetivo:** Blob emulator para checkpoints (Inventory + Analytics).

### Enfoque A — Consola AWS

1. Task definition `shopdemo-azurite`
2. Image: `mcr.microsoft.com/azure-storage/azurite`
3. Command: `azurite-blob,--blobHost,0.0.0.0,--blobPort,10000`
4. Port 10000, service con 1 tarea, SG `sg-data-shopdemo`

### Enfoque B — AWS CLI

Similar al paso Postgres: family `shopdemo-azurite`, imagen Azurite, puerto 10000, service `shopdemo-azurite`.

Actualizar parámetro SSM `/shopdemo/azurite-checkpoint` con `BlobEndpoint=http://<IP_AZURITE>:10000/devstoreaccount1`.

---

## 12. Paso 10 — Cloud Map (Inventory)

**Objetivo:** Que Orders resuelva `inventory` por nombre DNS interno.

### Enfoque A — Consola AWS

1. **Cloud Map** → **Create namespace**
2. Type: **DNS private** en VPC `shopdemo-vpc`
3. Name: `shopdemo.local`
4. Al crear el ECS service de Inventory, en **Service discovery**:
   - Namespace: `shopdemo.local`
   - Service name: `inventory`
   - DNS record type: A

### Enfoque B — AWS CLI

```bash
$NS_ID = aws servicediscovery create-private-dns-namespace \
  --name shopdemo.local --vpc $VPC_ID --query OperationId --output text

# Esperar a que la operación termine; luego obtener NamespaceId en Cloud Map console

$INV_SD_ARN = aws servicediscovery create-service \
  --name inventory \
  --namespace-id <NAMESPACE_ID> \
  --dns-config "NamespaceId=<NAMESPACE_ID>,DnsRecords=[{Type=A,TTL=10}]" \
  --health-check-custom-config FailureThreshold=1 \
  --query Service.Arn --output text
```

Al crear el ECS service Inventory, asociar `serviceRegistries` con el ARN de Cloud Map.

**URL para Orders:**

```
InventoryApi__BaseUrl=http://inventory.shopdemo.local:8080
```

---

## 13. Paso 11 — ALB + Catalog

**Objetivo:** Primera API pública detrás de Application Load Balancer.

### Enfoque A — Consola AWS

1. **EC2** → **Load Balancers** → **Create** → **Application Load Balancer**
2. Name: `alb-shopdemo-catalog`, Scheme: internet-facing, IP: IPv4
3. VPC + subnets públicas, SG `sg-alb-shopdemo`
4. Listener HTTP 80 → Target Group:
   - Target type: IP
   - Port 8080, health check `/health` o `/swagger/index.html`
5. **ECS** → Create service `shopdemo-catalog`:
   - Task def: imagen ECR catalog, CPU 512, mem 1024
   - Load balancer: asociar target group
   - Env vars desde Parameter Store (secrets)

### Enfoque B — AWS CLI (resumen)

```bash
# Target group
$TG_CATALOG = aws elbv2 create-target-group --name tg-catalog --protocol HTTP --port 8080 \
  --vpc-id $VPC_ID --target-type ip --health-check-path /health \
  --query TargetGroups[0].TargetGroupArn --output text

# ALB + listener (crear ALB, listener 80 → $TG_CATALOG)
# Registrar task definition shopdemo-catalog con secrets de SSM
# create-service con loadBalancers apuntando al TG
```

Variables mínimas en la task definition Catalog:

- `ConnectionStrings__DefaultConnection` ← SSM `/shopdemo/pg-catalog`
- `EventHubs__Enabled=true`
- `EventHubs__ConnectionString` ← SSM `/shopdemo/eh-connection`
- `EventHubs__EventHubName=shopdemo-events`

---

## 14. Paso 12 — Desplegar Inventory (interno)

**Objetivo:** Servicio sin ALB público; registrado en Cloud Map.

### Enfoque A — Consola AWS

1. Task definition `shopdemo-inventory` (imagen ECR)
2. Create service **sin** load balancer
3. **Service discovery:** `inventory.shopdemo.local`
4. Variables Event Hubs + consumer group + checkpoint Azurite

### Enfoque B — AWS CLI

```bash
aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-inventory \
  --task-definition shopdemo-inventory \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}" \
  --service-registries "registryArn=$INV_SD_ARN"
```

---

## 15. Paso 13 — Desplegar Orders

**Objetivo:** ALB propio + `InventoryApi__BaseUrl` hacia Cloud Map.

### Enfoque A — Consola AWS

1. ALB `alb-shopdemo-orders` (o reglas en ALB compartido con host `orders.lab`)
2. ECS service `shopdemo-orders` con:
   - `InventoryApi__BaseUrl=http://inventory.shopdemo.local:8080`
   - Secrets PG y Event Hubs

### Enfoque B — AWS CLI

Mismo patrón que Catalog: target group + ALB + service con env var `InventoryApi__BaseUrl`.

---

## 16. Paso 14 — Desplegar Analytics

**Objetivo:** API pública con ALB; consumer group `analytics-service`.

### Enfoque A — Consola AWS

1. ALB `alb-shopdemo-analytics`
2. Task definition con Event Hubs + checkpoint `analytics-checkpoints`
3. Service con desired count 1

### Enfoque B — AWS CLI

Repetir patrón ALB + ECS service con imagen `shopdemo-analytics:latest`.

---

## 17. Paso 15 — Probar el flujo

| # | Acción | URL |
|---|---|---|
| 1 | Swagger Catalog | `http://<alb-catalog-dns>/swagger` |
| 2 | Crear producto | `POST /api/products` |
| 3 | Analytics | `http://<alb-analytics-dns>/api/analytics/events` |
| 4 | Pedido + confirmar | Orders ALB |
| 5 | Logs | CloudWatch → Log groups `/ecs/shopdemo-*` |

---

## 18. Paso 16 — GitHub Actions

Archivo: `.github/workflows/deploy-aws.yml`

### Secrets GitHub

| Secret | Descripción |
|---|---|
| `AWS_ROLE_ARN` | Rol IAM para OIDC (recomendado) o access key |
| `AWS_REGION` | `us-east-1` |
| `ECS_CLUSTER` | `shopdemo-cluster` |

### Enfoque A — Consola (OIDC)

1. IAM → Identity providers → GitHub OIDC
2. Rol con trust policy para tu repo
3. Políticas: `AmazonEC2ContainerRegistryPowerUser`, `AmazonECS_FullAccess`

### Enfoque B — CLI

El workflow hace login ECR, build/push de las 4 imágenes y `aws ecs update-service --force-new-deployment` por servicio.

---

## 19. Paso 17 — Limpieza

### Consola

Eliminar en orden: ECS services → ALB → target groups → ECR images → cluster → VPC (o usar **CloudFormation** si creaste stack).

### CLI

```bash
aws ecs delete-service --cluster $CLUSTER --service shopdemo-catalog --force
# Repetir por cada servicio; luego eliminar ALB, TG, ECR, cluster, VPC
```

---

## 20. Solución de problemas

| Síntoma | Causa | Solución |
|---|---|---|
| Task stopped immediately | Imagen o puerto | Revisar CloudWatch Logs |
| Orders no alcanza Inventory | Cloud Map mal configurado | Verificar `inventory.shopdemo.local` desde tarea Orders |
| Sin eventos | Egress bloqueado | SG debe permitir salida 443 a internet |
| Health check falla | Ruta incorrecta | Usar `/health` si existe; si no, `/swagger` |
| Pull ECR denied | Task execution role | Asignar `AmazonECSTaskExecutionRolePolicy` |

---

## Referencias

- [TEORIA-CONTENEDORES-AWS.md](./TEORIA-CONTENEDORES-AWS.md)
- [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./REQUERIMIENTOS-DESPLIEGUE-AWS.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
