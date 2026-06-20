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
**Script automatizado (CLI):** [scripts/aws/README.md](../../../scripts/aws/README.md) — `Deploy-AwsShopDemo.ps1` / `Remove-AwsShopDemo.ps1`  
**Qué integrar:** `Dockerfile` y `docker-compose.yml` de cada API; parámetros SSM/Secrets Manager — **sin código C# nuevo**.

### Servicios AWS del release productivo (lab)

| Componente ShopDemo | Servicio AWS | Notas |
|---|---|---|
| Imágenes Docker | **Amazon ECR** (5 repos) | `shopdemo-catalog` … `shopdemo-mcp` |
| Cómputo APIs | **ECS Fargate** | 5 services + Postgres + Azurite |
| Entrada HTTP pública | **Application Load Balancer** | Un ALB por API pública |
| DNS interno Inventory | **AWS Cloud Map** | `inventory.shopdemo.local` |
| Secretos | **SSM Parameter Store** (SecureString) | `/shopdemo/*` |
| Red | **VPC** + Security Groups | Subnets públicas (lab) |
| Mensajería | **Azure Event Hubs** (cross-cloud) | Connection string en SSM |
| Checkpoints Blob | **Azurite** en Fargate | Emulador; en Azure ACA usa Storage Account |

### Convención de nombres del laboratorio (prefijo `shopdemo`)

> Todas las variables están en `scripts/aws/.env.aws.example`. El prefijo `LAB_PREFIX=shopdemo` se antepone a VPC, security groups, task families y ALB.

| Recurso AWS | Nombre canónico | Variable `.env.aws` | Para qué sirve |
|---|---|---|---|
| Región | `us-east-1` | `AWS_REGION` | Región donde se crean los recursos |
| Prefijo recursos | `shopdemo` | `LAB_PREFIX` | Prefijo común (VPC, SG, ECS family, ALB) |
| VPC | `shopdemo-vpc` (tag Name) | `VPC_CIDR` = `10.0.0.0/16` | Red privada para Fargate y ALB |
| Security Group ALB | `shopdemo-alb` | — | Recibe HTTP:80 desde internet |
| Security Group apps | `shopdemo-apps` | — | Tareas ECS de las APIs |
| Security Group datos | `shopdemo-data` | — | PostgreSQL y Azurite |
| ECR repos | `shopdemo-catalog`, …, `shopdemo-mcp` | `IMAGE_TAG` | Registro de imágenes Docker |
| SSM parameters | `/shopdemo/eh-connection`, `/shopdemo/pg-catalog`, … | — | Secretos fuera de task definitions |
| ECS cluster | `shopdemo-cluster` | `ECS_CLUSTER_NAME` | Agrupa servicios Fargate |
| Task family Postgres | `shopdemo-postgres` | — | Definición del contenedor PostgreSQL |
| ECS service Postgres | `shopdemo-postgres` | — | Tarea Fargate de base de datos |
| Task/Service Azurite | `shopdemo-azurite` | — | Emulador Blob para checkpoints |
| Cloud Map namespace | `shopdemo.local` | `CLOUDMAP_NAMESPACE` | DNS privado VPC |
| Cloud Map service | `inventory` | — | Resuelve `inventory.shopdemo.local` |
| Task/Service Catalog | `shopdemo-catalog` | — | API catálogo + ALB público |
| ALB Catalog | `shopdemo-catalog-alb` | — | Entrada HTTP pública Catalog |
| Target group Catalog | `shopdemo-catalog-tg` | — | Health check hacia puerto 8080 |
| Task/Service Inventory | `shopdemo-inventory` | — | API interna (sin ALB) |
| Task/Service Orders | `shopdemo-orders` | — | API pedidos + ALB |
| ALB Orders | `shopdemo-orders-alb` | — | Entrada HTTP Orders |
| Task/Service Analytics | `shopdemo-analytics` | — | API analytics + ALB |
| ALB Analytics | `shopdemo-analytics-alb` | — | Entrada HTTP Analytics |
| Task/Service MCP | `shopdemo-mcp` | — | Gateway MCP + ALB |
| ALB MCP | `shopdemo-mcp-alb` | — | Entrada HTTP MCP |
| Event Hubs | *(Azure)* `shopdemo-eh-ns-lab01` / `shopdemo-events` | `EVENT_HUBS_CONNECTION_STRING` | Mensajería cross-cloud |

---

## Índice

0. [**Script PowerShell automatizado (recomendado)**](#0-script-powershell-automatizado-recomendado)
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
17. [Paso 15 — Desplegar MCP Gateway](#17-paso-15--desplegar-mcp-gateway)
18. [Paso 16 — Probar el flujo](#18-paso-16--probar-el-flujo)
19. [Paso 17 — GitHub Actions](#19-paso-17--github-actions)
20. [Paso 18 — Limpieza](#20-paso-18--limpieza)
21. [Solución de problemas](#21-solución-de-problemas)
22. [Anexo — Task definitions ECS (copiar)](#22-anexo--task-definitions-ecs-copiar)

---

## 0. Script PowerShell automatizado (recomendado)

Provisiona la infraestructura AWS del curso (ECS Fargate, EKS o ambos) desde PowerShell, alineado con los pasos manuales de este documento.

| Recurso | Ruta |
|---|---|
| Scripts | [scripts/aws/](../../../scripts/aws/) |
| Guía detallada | [scripts/aws/README.md](../../../scripts/aws/README.md) |
| Plantilla de variables | [scripts/aws/.env.aws.example](../../../scripts/aws/.env.aws.example) |

> El script **no hace build ni push** a ECR. Tras ejecutarlo, publica las 5 imágenes (§7 y §16).

### Cuándo usar cada modo

| Modo | Comando | Qué crea | Etapa del curso |
|---|---|---|---|
| **ECS** | `.\Deploy-AwsShopDemo.ps1 -Mode ECS` | VPC, ECR, SSM, cluster ECS, Postgres/Azurite Fargate, Cloud Map, 5 APIs + MCP con ALB | 8 + 14b |
| **EKS** | `.\Deploy-AwsShopDemo.ps1 -Mode EKS` | ECR, cluster EKS (eksctl), Ingress Helm, `k8s/secrets.yaml` | 11 |
| **All** | `.\Deploy-AwsShopDemo.ps1 -Mode All` | ECS + EKS | 8 + 11 |

Event Hubs **no se crea en AWS**: la mensajería sigue en **Azure** (cross-cloud). Debes pegar la connection string en `.env.aws`.

### Paso A — Configurar variables (`.env.aws`)

```powershell
cd I:\Curso\ShopDemo\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws
```

| Variable | Obligatorio | Dónde obtenerlo |
|---|---|---|
| `AWS_REGION` | Sí | Consola AWS (barra superior) o `aws configure` |
| `EVENT_HUBS_CONNECTION_STRING` | Sí | **Azure Portal** → Event Hubs → Shared access policies → **RootManageSharedAccessKey** ([§4.4 Azure](../../INTEGRACION-AZURE-EVENT-HUBS.md#44-obtener-connection-string-del-namespace)) |
| `EVENT_HUB_NAME` | Sí | Nombre del hub (`shopdemo-events`) |
| `LAB_PREFIX` | Sí | Prefijo de recursos (`shopdemo`) |
| `ECS_CLUSTER_NAME` | Modo ECS/All | Nombre del cluster Fargate |
| `EKS_CLUSTER_NAME` | Modo EKS/All | Nombre del cluster EKS |
| `POSTGRES_PASSWORD` | Modo ECS/All | Contraseña PostgreSQL en Fargate |
| `IMAGE_TAG` | Recomendado | Tag en ECR (`latest`) |

Credenciales AWS: `aws configure` (Access Key de IAM → **Security credentials**).

### Paso B — Login y ejecución

```powershell
aws configure
aws sts get-caller-identity

# ECS Fargate + ALB (release sin Kubernetes)
.\Deploy-AwsShopDemo.ps1 -Mode ECS

# O EKS
.\Deploy-AwsShopDemo.ps1 -Mode EKS

# O ambos
.\Deploy-AwsShopDemo.ps1 -Mode All
```

El script guarda estado en `scripts/aws/.deploy-state.json` (no commitear) y muestra DNS de los ALB al terminar (modo ECS).

### Paso C — Publicar imágenes en ECR (obligatorio)

| Opción | Cómo |
|---|---|
| **GitHub Actions** | Secrets `AWS_REGION`, `ECS_CLUSTER`, credenciales OIDC o access key → [.github/workflows/deploy-aws.yml](../../../.github/workflows/deploy-aws.yml) |
| **Manual** | `aws ecr get-login-password` + `docker build` + `docker push` — ver [§7](#7-paso-5--build-y-push-de-imágenes) |

Repos: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp`.

### Paso D — Validar release

| Modo | Verificación |
|---|---|
| **ECS** | `http://<alb-catalog-dns>/swagger` · Orders confirma vía Cloud Map `inventory.shopdemo.local` |
| **EKS** | Imágenes ECR en `k8s/*/deployment.yaml` → `kubectl apply -f k8s/` ([IMPLEMENTACION-DESPLIEGUE-EKS](../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)) |

Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md).

### Paso E — Limpieza

```powershell
.\Remove-AwsShopDemo.ps1
# Confirma escribiendo: delete-<LAB_PREFIX>
```

Ver también [§20 Limpieza](#20-paso-18--limpieza).

### Relación script ↔ secciones manuales

| Script | Equivalente manual |
|---|---|
| VPC + Security Groups | §4–§5 |
| ECR | §6 |
| SSM Parameter Store | §8 |
| ECS cluster + Postgres + Azurite | §9–§11 |
| Cloud Map + APIs + ALB | §12–§16 |
| MCP | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS](../../integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |
| EKS + secrets | [IMPLEMENTACION-DESPLIEGUE-EKS](../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |

---

## 1. Prerequisitos

- Cuenta AWS con permisos administrador (lab)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Docker Desktop
- Repositorio ShopDemo clonado
- Event Hubs en Azure configurado (connection string)

---

## 2. Variables del laboratorio

Usa los nombres canónicos de la tabla superior (alineados con `Deploy-AwsShopDemo.ps1`).

```powershell
$AWS_REGION = "us-east-1"
$PREFIX = "shopdemo"                    # LAB_PREFIX
$CLUSTER = "shopdemo-cluster"         # ECS_CLUSTER_NAME
$VPC_NAME = "shopdemo-vpc"
$CLOUDMAP_NS = "shopdemo.local"
$PG_PASSWORD = "ShopDemo123!"
$EH_CONN = "<EVENT_HUBS_CONNECTION_STRING>"   # desde Azure Portal
```

```bash
export AWS_REGION=us-east-1
export PREFIX=shopdemo
export CLUSTER=shopdemo-cluster
export CLOUDMAP_NS=shopdemo.local
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

**Para qué sirve:** red aislada donde corren las tareas Fargate, los ALB y la resolución DNS interna (Cloud Map).

**Nombre VPC (tag):** `shopdemo-vpc` · CIDR: `10.0.0.0/16`

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

**Para qué sirve:** firewall de la VPC; controla tráfico entre internet → ALB → APIs → Postgres/Azurite.

| Security Group (nombre) | Para qué sirve |
|---|---|
| `shopdemo-alb` | Application Load Balancers (HTTP:80 desde internet) |
| `shopdemo-apps` | Tareas ECS de las 5 APIs |
| `shopdemo-data` | PostgreSQL y Azurite (solo tráfico desde `shopdemo-apps`) |

### Enfoque A — Consola AWS

1. **EC2** → **Security Groups** → **Create security group**

**SG `shopdemo-alb`:**
- Inbound: HTTP 80 desde `0.0.0.0/0`
- Outbound: All

**SG `shopdemo-apps`:**
- Inbound: TCP 8080 desde SG `shopdemo-alb`
- Inbound: TCP 8080 desde SG `shopdemo-apps` (Orders → Inventory)
- Outbound: All (salida HTTPS a Azure Event Hubs)

**SG `shopdemo-data`:**
- Inbound: TCP 5432 y 10000 solo desde SG `shopdemo-apps`

### Enfoque B — AWS CLI

```bash
$SG_ALB = aws ec2 create-security-group --group-name shopdemo-alb \
  --description "ALB ShopDemo" --vpc-id $VPC_ID --query GroupId --output text

$SG_APPS = aws ec2 create-security-group --group-name shopdemo-apps \
  --description "ECS apps ShopDemo" --vpc-id $VPC_ID --query GroupId --output text

$SG_DATA = aws ec2 create-security-group --group-name shopdemo-data \
  --description "Postgres Azurite ShopDemo" --vpc-id $VPC_ID --query GroupId --output text

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

**Para qué sirve:** registro privado de imágenes Docker; cada API tiene su propio repositorio.

**Repositorios (5):** `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp`

### Enfoque A — Consola AWS

1. **Amazon ECR** → **Create repository**
2. Crear: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp`
3. Visibility: **Private**

### Enfoque B — AWS CLI

```bash
foreach ($repo in @("shopdemo-catalog","shopdemo-orders","shopdemo-inventory","shopdemo-analytics","shopdemo-mcp")) {
  aws ecr create-repository --repository-name $repo --region $AWS_REGION
}
```

```bash
# Bash
for repo in shopdemo-catalog shopdemo-orders shopdemo-inventory shopdemo-analytics shopdemo-mcp; do
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

docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t $ECR_URI/shopdemo-mcp:latest .
docker push $ECR_URI/shopdemo-mcp:latest
```

**Verificación:**

```bash
aws ecr list-images --repository-name shopdemo-catalog --region $AWS_REGION
```

---

## 8. Paso 6 — Secrets (Parameter Store)

**Para qué sirve:** almacén central de cadenas de conexión; las task definitions las referencian sin exponer texto plano.

**Prefijo:** `/shopdemo/` (coincide con `LAB_PREFIX`)

### Enfoque A — Consola AWS

1. **Systems Manager** → **Parameter Store** → **Create parameter**
2. Crear parámetros **SecureString** (nombre exacto):

| Nombre SSM | Contenido |
|---|---|
| `/shopdemo/eh-connection` | Connection string Azure Event Hubs |
| `/shopdemo/pg-catalog` | `Host=<IP_POSTGRES>;...Database=ShopDemoCatalog;...` |
| `/shopdemo/pg-orders` | Connection string Orders |
| `/shopdemo/pg-inventory` | Connection string Inventory |
| `/shopdemo/azurite-checkpoint` | Connection string Azurite Blob |

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

**Para qué sirve:** agrupador lógico de servicios Fargate; todos los `shopdemo-*` services viven aquí.

**Nombre:** `shopdemo-cluster` (variable `$CLUSTER`)

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

**Para qué sirve:** base de datos PostgreSQL en Fargate; las APIs se conectan por IP privada de la tarea.

| Campo | Valor |
|---|---|
| Task definition family | `shopdemo-postgres` |
| ECS service name | `shopdemo-postgres` |
| Container name | `postgres` |
| Log group | `/ecs/shopdemo-postgres` |

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
   - Cluster: `shopdemo-cluster`
   - Desired tasks: 1
   - Subnets públicas, SG `shopdemo-data`
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

**Para qué sirve:** emulador de Azure Blob Storage para checkpoints de Event Hubs en Inventory y Analytics.

| Campo | Valor |
|---|---|
| Task definition family | `shopdemo-azurite` |
| ECS service name | `shopdemo-azurite` |
| Log group | `/ecs/shopdemo-azurite` |

### Enfoque A — Consola AWS

1. Task definition `shopdemo-azurite`
2. Image: `mcr.microsoft.com/azure-storage/azurite`
3. Command: `azurite-blob,--blobHost,0.0.0.0,--blobPort,10000`
4. Port 10000, service `shopdemo-azurite`, cluster `shopdemo-cluster`, SG `shopdemo-data`

### Enfoque B — AWS CLI

Crear archivo `ecs-azurite-task.json`:

```json
{
  "family": "shopdemo-azurite",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "azurite",
      "image": "mcr.microsoft.com/azure-storage/azurite",
      "essential": true,
      "command": ["azurite-blob", "--blobHost", "0.0.0.0", "--blobPort", "10000"],
      "portMappings": [{ "containerPort": 10000, "protocol": "tcp" }],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-azurite",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```bash
aws logs create-log-group --log-group-name /ecs/shopdemo-azurite
aws ecs register-task-definition --cli-input-json file://ecs-azurite-task.json

aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-azurite \
  --task-definition shopdemo-azurite \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A],securityGroups=[$SG_DATA],assignPublicIp=ENABLED}"

# Obtener IP privada de la tarea Azurite
$AZ_TASK = aws ecs list-tasks --cluster $CLUSTER --service-name shopdemo-azurite --query "taskArns[0]" --output text
$AZ_IP = aws ecs describe-tasks --cluster $CLUSTER --tasks $AZ_TASK \
  --query "tasks[0].attachments[0].details[?name=='privateIPv4Address'].value" --output text

$AZ_CONN = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://${AZ_IP}:10000/devstoreaccount1;"
aws ssm put-parameter --name /shopdemo/azurite-checkpoint --value "$AZ_CONN" --type SecureString --overwrite
```

---

## 12. Paso 10 — Cloud Map (Inventory)

**Para qué sirve:** DNS privado dentro de la VPC para que Orders resuelva Inventory sin IP fija.

| Campo | Valor |
|---|---|
| Namespace | `shopdemo.local` |
| Service discovery name | `inventory` |
| FQDN resultante | `inventory.shopdemo.local` |
| URL para Orders | `http://inventory.shopdemo.local:8080` |

### Enfoque A — Consola AWS

1. **Cloud Map** → **Create namespace**
2. Type: **DNS private** en VPC `shopdemo-vpc`
3. Name: `shopdemo.local` → **Create**
4. Al crear el ECS service `shopdemo-inventory`, en **Service discovery**:
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

**Para qué sirve:** Application Load Balancer expone Catalog a internet (HTTP:80 → contenedor:8080).

| Campo | Valor |
|---|---|
| ALB name | `shopdemo-catalog-alb` |
| Target group | `shopdemo-catalog-tg` |
| ECS service | `shopdemo-catalog` |
| Task family | `shopdemo-catalog` |
| Container name | `catalog-api` |
| Security group ALB | `shopdemo-alb` |

### Enfoque A — Consola AWS

1. **EC2** → **Load Balancers** → **Create** → **Application Load Balancer**
2. Name: `shopdemo-catalog-alb`, Scheme: internet-facing, IP: IPv4
3. VPC `shopdemo-vpc` + subnets públicas, SG `shopdemo-alb`
4. Listener HTTP 80 → Target Group `shopdemo-catalog-tg`:
   - Target type: IP
   - Port 8080, health check `/health` o `/swagger/index.html`
5. **ECS** → Cluster `shopdemo-cluster` → Create service `shopdemo-catalog`:
   - Task def: imagen ECR catalog, CPU 512, mem 1024
   - Load balancer: asociar target group
   - Env vars desde Parameter Store (secrets)

### Enfoque B — AWS CLI

> **Recomendación lab:** Si prefieres no escribir todo el JSON a mano, ejecuta `.\Deploy-AwsShopDemo.ps1 -Mode ECS` (§0) y usa este apartado para **entender** cada recurso. Los JSON del [Anexo §22](#22-anexo--task-definitions-ecs-copiar) son copiables para ruta 100 % manual.

**1. Rol de ejecución ECS** (pull ECR + leer SSM):

```bash
# Crear rol ecsTaskExecutionRole si no existe (una vez por cuenta)
aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
$EXEC_ROLE = aws iam get-role --role-name ecsTaskExecutionRole --query Role.Arn --output text
```

**2. Task definition Catalog** — archivo `ecs-catalog-task.json` (ver [Anexo §22.1](#221-catalog)):

```bash
aws logs create-log-group --log-group-name /ecs/shopdemo-catalog
aws ecs register-task-definition --cli-input-json file://ecs-catalog-task.json
```

**3. Target group + ALB + listener:**

```bash
$TG_CATALOG = aws elbv2 create-target-group --name shopdemo-catalog-tg --protocol HTTP --port 8080 \
  --vpc-id $VPC_ID --target-type ip --health-check-path /health \
  --query TargetGroups[0].TargetGroupArn --output text

$ALB_CATALOG = aws elbv2 create-load-balancer --name shopdemo-catalog-alb \
  --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB \
  --scheme internet-facing --type application \
  --query LoadBalancers[0].LoadBalancerArn --output text

aws elbv2 create-listener --load-balancer-arn $ALB_CATALOG --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_CATALOG
```

**4. ECS service Catalog con ALB:**

```bash
aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-catalog \
  --task-definition shopdemo-catalog \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_CATALOG,containerName=catalog-api,containerPort=8080"

$ALB_DNS = aws elbv2 describe-load-balancers --load-balancer-arns $ALB_CATALOG \
  --query "LoadBalancers[0].DNSName" --output text
echo "Catalog: http://$ALB_DNS/swagger"
```

Variables en la task definition Catalog (secrets SSM):

- `ConnectionStrings__DefaultConnection` ← `/shopdemo/pg-catalog`
- `EventHubs__ConnectionString` ← `/shopdemo/eh-connection`
- `EventHubs__Enabled=true`, `EventHubs__EventHubName=shopdemo-events`

---

## 14. Paso 12 — Desplegar Inventory (interno)

**Para qué sirve:** API de inventario **sin** ALB público; Orders la alcanza vía `inventory.shopdemo.local`.

| Campo | Valor |
|---|---|
| ECS service | `shopdemo-inventory` |
| Task family | `shopdemo-inventory` |
| Cloud Map | `inventory` en namespace `shopdemo.local` |

### Enfoque A — Consola AWS

1. Task definition `shopdemo-inventory` (imagen ECR)
2. Create service **sin** load balancer
3. **Service discovery:** `inventory.shopdemo.local`
4. Variables Event Hubs + consumer group + checkpoint Azurite

### Enfoque B — AWS CLI

```bash
aws logs create-log-group --log-group-name /ecs/shopdemo-inventory
aws ecs register-task-definition --cli-input-json file://ecs-inventory-task.json

aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-inventory \
  --task-definition shopdemo-inventory \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}" \
  --service-registries "registryArn=$INV_SD_ARN,containerName=inventory-api"
```

JSON de referencia: [Anexo §22.2](#222-inventory). Secrets: PG inventory, EH, `azurite-checkpoint`. Env: `EventHubs__ConsumerGroup=inventory-service`, `EventHubs__CheckpointContainerName=inventory-checkpoints`.

---

## 15. Paso 13 — Desplegar Orders

**Para qué sirve:** API de pedidos con ALB propio; usa Cloud Map para llamar a Inventory.

| Campo | Valor |
|---|---|
| ALB | `shopdemo-orders-alb` |
| Target group | `shopdemo-orders-tg` |
| ECS service | `shopdemo-orders` |
| Env var clave | `InventoryApi__BaseUrl=http://inventory.shopdemo.local:8080` |

### Enfoque A — Consola AWS

1. ALB `shopdemo-orders-alb` + target group `shopdemo-orders-tg`
2. ECS service `shopdemo-orders` en cluster `shopdemo-cluster` con:
   - `InventoryApi__BaseUrl=http://inventory.shopdemo.local:8080`
   - Secrets PG y Event Hubs

### Enfoque B — AWS CLI

Registrar task definition **después** de Inventory (necesita URL Cloud Map):

```bash
# URL interna Inventory (Orders la usa)
$INVENTORY_URL = "http://inventory.shopdemo.local:8080"

aws logs create-log-group --log-group-name /ecs/shopdemo-orders
aws ecs register-task-definition --cli-input-json file://ecs-orders-task.json

$TG_ORDERS = aws elbv2 create-target-group --name shopdemo-orders-tg --protocol HTTP --port 8080 \
  --vpc-id $VPC_ID --target-type ip --health-check-path /health \
  --query TargetGroups[0].TargetGroupArn --output text

$ALB_ORDERS = aws elbv2 create-load-balancer --name shopdemo-orders-alb \
  --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB \
  --scheme internet-facing --type application \
  --query LoadBalancers[0].LoadBalancerArn --output text

aws elbv2 create-listener --load-balancer-arn $ALB_ORDERS --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ORDERS

aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-orders \
  --task-definition shopdemo-orders \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ORDERS,containerName=orders-api,containerPort=8080"
```

JSON: [Anexo §22.3](#223-orders). Variable clave: `InventoryApi__BaseUrl=$INVENTORY_URL`.

---

## 16. Paso 14 — Desplegar Analytics

**Para qué sirve:** API observador de eventos; consumer group `analytics-service` y checkpoints en Azurite.

| Campo | Valor |
|---|---|
| ALB | `shopdemo-analytics-alb` |
| Target group | `shopdemo-analytics-tg` |
| ECS service | `shopdemo-analytics` |

### Enfoque A — Consola AWS

1. ALB `shopdemo-analytics-alb` + TG `shopdemo-analytics-tg`
2. Task definition con Event Hubs + checkpoint `analytics-checkpoints`
3. Service con desired count 1

### Enfoque B — AWS CLI

```bash
aws logs create-log-group --log-group-name /ecs/shopdemo-analytics
aws ecs register-task-definition --cli-input-json file://ecs-analytics-task.json

$TG_ANALYTICS = aws elbv2 create-target-group --name shopdemo-analytics-tg --protocol HTTP --port 8080 \
  --vpc-id $VPC_ID --target-type ip --health-check-path /health \
  --query TargetGroups[0].TargetGroupArn --output text

$ALB_ANALYTICS = aws elbv2 create-load-balancer --name shopdemo-analytics-alb \
  --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB \
  --scheme internet-facing --type application \
  --query LoadBalancers[0].LoadBalancerArn --output text

aws elbv2 create-listener --load-balancer-arn $ALB_ANALYTICS --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ANALYTICS

aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-analytics \
  --task-definition shopdemo-analytics \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ANALYTICS,containerName=analytics-api,containerPort=8080"
```

JSON: [Anexo §22.4](#224-analytics).

---

## 17. Paso 15 — Desplegar MCP Gateway

**Para qué sirve:** quinta API pública; gateway MCP para agentes IA.

| Campo | Valor |
|---|---|
| ALB | `shopdemo-mcp-alb` |
| Target group | `shopdemo-mcp-tg` |
| ECS service | `shopdemo-mcp` |
| Container name | `mcp-api` |

### Enfoque A — Consola AWS

1. Task definition `shopdemo-mcp` (imagen ECR `shopdemo-mcp`, sin secrets SSM)
2. Variables:
   - `ShopDemo__CatalogApiBaseUrl=http://<dns-shopdemo-catalog-alb>`
   - `ShopDemo__InventoryApiBaseUrl=http://inventory.shopdemo.local:8080`
   - `ShopDemo__AnalyticsApiBaseUrl=http://<dns-shopdemo-analytics-alb>`
3. ALB `shopdemo-mcp-alb` + ECS service `shopdemo-mcp`

### Enfoque B — AWS CLI

```bash
$ALB_CATALOG_DNS = aws elbv2 describe-load-balancers --names shopdemo-catalog-alb \
  --query "LoadBalancers[0].DNSName" --output text
$ALB_ANALYTICS_DNS = aws elbv2 describe-load-balancers --names shopdemo-analytics-alb \
  --query "LoadBalancers[0].DNSName" --output text

# Editar ecs-mcp-task.json con esas URLs antes de registrar
aws logs create-log-group --log-group-name /ecs/shopdemo-mcp
aws ecs register-task-definition --cli-input-json file://ecs-mcp-task.json

$TG_MCP = aws elbv2 create-target-group --name shopdemo-mcp-tg --protocol HTTP --port 8080 \
  --vpc-id $VPC_ID --target-type ip --health-check-path /health \
  --query TargetGroups[0].TargetGroupArn --output text

$ALB_MCP = aws elbv2 create-load-balancer --name shopdemo-mcp-alb \
  --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB \
  --scheme internet-facing --type application \
  --query LoadBalancers[0].LoadBalancerArn --output text

aws elbv2 create-listener --load-balancer-arn $ALB_MCP --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_MCP

aws ecs create-service \
  --cluster $CLUSTER \
  --service-name shopdemo-mcp \
  --task-definition shopdemo-mcp \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_MCP,containerName=mcp-api,containerPort=8080"
```

JSON: [Anexo §22.5](#225-mcp). Detalle: [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../../integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md).

---

## 18. Paso 16 — Probar el flujo

| # | Acción | URL |
|---|---|---|
| 1 | Swagger Catalog | `http://<alb-catalog-dns>/swagger` |
| 2 | Crear producto | `POST /api/products` |
| 3 | Analytics | `http://<alb-analytics-dns>/api/analytics/events` |
| 4 | Pedido + confirmar | Orders ALB |
| 5 | MCP health | `http://<alb-mcp-dns>/health` |
| 6 | Logs | CloudWatch → Log groups `/ecs/shopdemo-*` |

---

## 19. Paso 17 — GitHub Actions

Archivo de referencia: [.github/workflows/deploy-aws.yml](../../../.github/workflows/deploy-aws.yml)

### Secrets GitHub

| Secret | Descripción |
|---|---|
| `AWS_ROLE_ARN` | Rol IAM para OIDC (recomendado) o access key |
| `AWS_REGION` | `us-east-1` |
| `ECS_CLUSTER` | `shopdemo-cluster` |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Alternativa sin OIDC |

### Enfoque A — Consola (OIDC)

1. IAM → Identity providers → GitHub OIDC
2. Rol con trust policy para tu repo
3. Políticas: `AmazonEC2ContainerRegistryPowerUser`, `AmazonECS_FullAccess`

### Enfoque B — CLI

El workflow hace login ECR, build/push de las **5 imágenes** y `aws ecs update-service --force-new-deployment` por servicio (`shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp`).

---

## 20. Paso 18 — Limpieza

### Consola

Eliminar en orden: ECS services → ALB → target groups → ECR images → cluster → VPC (o usar **CloudFormation** si creaste stack).

### CLI

```bash
aws ecs delete-service --cluster $CLUSTER --service shopdemo-catalog --force
aws ecs delete-service --cluster $CLUSTER --service shopdemo-orders --force
aws ecs delete-service --cluster $CLUSTER --service shopdemo-inventory --force
aws ecs delete-service --cluster $CLUSTER --service shopdemo-analytics --force
aws ecs delete-service --cluster $CLUSTER --service shopdemo-mcp --force
aws ecs delete-service --cluster $CLUSTER --service shopdemo-postgres --force
aws ecs delete-service --cluster $CLUSTER --service shopdemo-azurite --force
# Luego eliminar ALB, TG, ECR, cluster, VPC — o usar .\Remove-AwsShopDemo.ps1
```

---

## 21. Solución de problemas

| Síntoma | Causa | Solución |
|---|---|---|
| Task stopped immediately | Imagen o puerto | Revisar CloudWatch Logs |
| Orders no alcanza Inventory | Cloud Map mal configurado | Verificar `inventory.shopdemo.local` desde tarea Orders |
| Sin eventos | Egress bloqueado | SG debe permitir salida 443 a internet |
| Health check falla | Ruta incorrecta | Usar `/health` si existe; si no, `/swagger` |
| Pull ECR denied | Task execution role | Asignar `AmazonECSTaskExecutionRolePolicy` |

---

## 22. Anexo — Task definitions ECS (copiar)

Plantillas para ruta manual. Sustituye:

- `<ACCOUNT_ID>`, `<AWS_REGION>`, `<ECR_URI>` (ej. `123456789.dkr.ecr.us-east-1.amazonaws.com`)
- `<EXEC_ROLE_ARN>` — rol `ecsTaskExecutionRole`
- En MCP: URLs reales de ALB Catalog/Analytics

Patrón común de secrets SSM en `secrets`:

```json
"secrets": [
  { "name": "ConnectionStrings__DefaultConnection", "valueFrom": "arn:aws:ssm:us-east-1:<ACCOUNT_ID>:parameter/shopdemo/pg-catalog" },
  { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:us-east-1:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" }
]
```

### 22.1 Catalog

Archivo `ecs-catalog-task.json`:

```json
{
  "family": "shopdemo-catalog",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [
    {
      "name": "catalog-api",
      "image": "<ECR_URI>/shopdemo-catalog:latest",
      "essential": true,
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
        { "name": "EventHubs__Enabled", "value": "true" },
        { "name": "EventHubs__EventHubName", "value": "shopdemo-events" }
      ],
      "secrets": [
        { "name": "ConnectionStrings__DefaultConnection", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/pg-catalog" },
        { "name": "EventHubs__ConnectionString", "valueFrom": "arn:aws:ssm:<AWS_REGION>:<ACCOUNT_ID>:parameter/shopdemo/eh-connection" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-catalog",
          "awslogs-region": "<AWS_REGION>",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### 22.2 Inventory

Archivo `ecs-inventory-task.json` — añade secrets `pg-inventory`, `azurite-checkpoint` y env `EventHubs__ConsumerGroup`, `EventHubs__CheckpointContainerName`.

### 22.3 Orders

Archivo `ecs-orders-task.json` — secrets `pg-orders`, `eh-connection`; env `InventoryApi__BaseUrl` = `http://inventory.shopdemo.local:8080`.

### 22.4 Analytics

Archivo `ecs-analytics-task.json` — secrets `eh-connection`, `azurite-checkpoint`; env consumer `analytics-service`, container `analytics-checkpoints`.

### 22.5 MCP

Archivo `ecs-mcp-task.json`:

```json
{
  "family": "shopdemo-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "<EXEC_ROLE_ARN>",
  "containerDefinitions": [
    {
      "name": "mcp-api",
      "image": "<ECR_URI>/shopdemo-mcp:latest",
      "essential": true,
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
        { "name": "ShopDemo__CatalogApiBaseUrl", "value": "http://<ALB_CATALOG_DNS>" },
        { "name": "ShopDemo__InventoryApiBaseUrl", "value": "http://inventory.shopdemo.local:8080" },
        { "name": "ShopDemo__AnalyticsApiBaseUrl", "value": "http://<ALB_ANALYTICS_DNS>" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-mcp",
          "awslogs-region": "<AWS_REGION>",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

> Los JSON completos de Inventory/Orders/Analytics siguen el mismo patrón que Catalog. Fuente de verdad en el repo: `scripts/aws/Deploy-AwsShopDemo.ps1` (función `Register-EcsTaskDefinition`).

---

## Referencias

- [TEORIA-CONTENEDORES-AWS.md](./TEORIA-CONTENEDORES-AWS.md)
- [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./REQUERIMIENTOS-DESPLIEGUE-AWS.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
