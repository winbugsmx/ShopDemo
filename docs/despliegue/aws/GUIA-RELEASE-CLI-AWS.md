# Guía — Release AWS con AWS CLI (manual)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Tiempo estimado** | 10–16 h (sin script) |
| **Cuándo usar** | Aprender cada servicio; el script no está disponible |

**Ruta rápida:** [GUIA-RELEASE-SCRIPT-AWS.md](./GUIA-RELEASE-SCRIPT-AWS.md)  
**Portal visual:** [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md)

> El release ECS manual son **~40 pasos**. Para el lab de 2 días usa el script y esta guía solo como referencia.

---

## Variables

```powershell
$AWS_REGION = "us-east-1"
$PREFIX = "shopdemo"
$CLUSTER = "shopdemo-cluster"
$VPC_NAME = "shopdemo-vpc"
$CLOUDMAP_NS = "shopdemo.local"
$PG_PASSWORD = "ShopDemo123!"
$EH_CONN = "<EVENT_HUBS_CONNECTION_STRING>"   # Azure Portal
```

Tabla de nombres: [IMPLEMENTACION-DESPLIEGUE-AWS.md](./IMPLEMENTACION-DESPLIEGUE-AWS.md).

---

## 0. IAM (antes de todo)

Adjunta **1 política** `ShopDemoLabECS` desde [`scripts/aws/iam-policy-shopdemo-lab-ecs.json`](../../../scripts/aws/iam-policy-shopdemo-lab-ecs.json).

```bash
cd I:\Curso\ShopDemo\scripts\aws
aws iam create-policy --policy-name ShopDemoLabECS \
  --policy-document file://iam-policy-shopdemo-lab-ecs.json

aws iam attach-user-policy --user-name TU_USUARIO \
  --policy-arn arn:aws:iam::TU_ACCOUNT_ID:policy/ShopDemoLabECS
```

Detalle visual: [GUIA-RELEASE-PORTAL-AWS.md §0](./GUIA-RELEASE-PORTAL-AWS.md#0-usuario-iam-y-permisos).

---

## 1. AWS CLI

```bash
aws configure
aws sts get-caller-identity
```

---

## 2. VPC y subnets

```bash
$VPC_ID = aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=shopdemo-vpc

$IGW = aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID

$SUBNET_A = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
  --availability-zone ${AWS_REGION}a --query Subnet.SubnetId --output text
$SUBNET_B = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
  --availability-zone ${AWS_REGION}b --query Subnet.SubnetId --output text

aws ec2 modify-subnet-attribute --subnet-id $SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_B --map-public-ip-on-launch
```

**Lab:** subnets públicas, **sin NAT Gateway** (más barato).

---

## 3. Security Groups

| SG | Nombre | Reglas clave |
|---|---|---|
| ALB | `shopdemo-alb` | Inbound HTTP 80 desde `0.0.0.0/0` |
| Apps | `shopdemo-apps` | Inbound 8080 desde ALB y desde sí mismo |
| Datos | `shopdemo-data` | Inbound 5432, 10000 solo desde apps |

```bash
$SG_ALB = aws ec2 create-security-group --group-name shopdemo-alb \
  --description "ALB ShopDemo" --vpc-id $VPC_ID --query GroupId --output text
$SG_APPS = aws ec2 create-security-group --group-name shopdemo-apps \
  --description "ECS apps ShopDemo" --vpc-id $VPC_ID --query GroupId --output text
$SG_DATA = aws ec2 create-security-group --group-name shopdemo-data \
  --description "Postgres Azurite ShopDemo" --vpc-id $VPC_ID --query GroupId --output text

aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_APPS --protocol tcp --port 8080 --source-group $SG_ALB
aws ec2 authorize-security-group-ingress --group-id $SG_APPS --protocol tcp --port 8080 --source-group $SG_APPS
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 5432 --source-group $SG_APPS
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 10000 --source-group $SG_APPS
```

---

## 4. ECR (5 repos)

```bash
foreach ($repo in @("shopdemo-catalog","shopdemo-orders","shopdemo-inventory","shopdemo-analytics","shopdemo-mcp")) {
  aws ecr create-repository --repository-name $repo --region $AWS_REGION
}

$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$ECR_URI = "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

---

## 5. Build y push

```bash
cd I:\Curso\ShopDemo
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $ECR_URI/shopdemo-catalog:latest .
docker push $ECR_URI/shopdemo-catalog:latest
# ... repetir orders, inventory, analytics, mcp
```

---

## 6. SSM Parameter Store

```bash
aws ssm put-parameter --name /shopdemo/eh-connection --value "$EH_CONN" --type SecureString --overwrite

# Tras Postgres:
$PG_HOST = "<IP_O_DNS_POSTGRES>"
aws ssm put-parameter --name /shopdemo/pg-catalog --value "Host=$PG_HOST;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=$PG_PASSWORD" --type SecureString --overwrite
# pg-orders, pg-inventory, azurite-checkpoint
```

---

## 7. ECS cluster

```bash
aws ecs create-cluster --cluster-name $CLUSTER --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1
```

Crear rol `shopdemo-ecs-execution` con trust `ecs-tasks.amazonaws.com` y políticas `AmazonECSTaskExecutionRolePolicy` + lectura SSM. El script lo hace automáticamente.

---

## 8. Postgres + Azurite (Fargate)

Orden: Postgres → crear 3 bases → Azurite → actualizar SSM con hosts reales.

Task definitions JSON: [ANEXO-TASK-DEFINITIONS-ECS.md](./ANEXO-TASK-DEFINITIONS-ECS.md)  
Fuente de verdad: `scripts/aws/Deploy-AwsShopDemo.ps1`.

---

## 9. Cloud Map

```bash
# Namespace shopdemo.local + servicio inventory → inventory.shopdemo.local
```

Orders usa `InventoryApi__BaseUrl=http://inventory.shopdemo.local:8080`.

---

## 10. APIs + ALB (orden)

1. **Catalog** — ALB `shopdemo-catalog-alb`, TG health `/health` o `/swagger`
2. **Inventory** — sin ALB (solo Cloud Map)
3. **Orders** — ALB `shopdemo-orders-alb`
4. **Analytics** — ALB `shopdemo-analytics-alb`
5. **MCP** — ALB `shopdemo-mcp-alb` + URLs de Catalog/Analytics

Patrón ALB por API: crear ALB → target group (puerto 8080) → listener HTTP:80 → ECS service con `loadBalancers`.

---

## 11. Validación

```bash
aws elbv2 describe-load-balancers --names shopdemo-catalog-alb --query 'LoadBalancers[0].DNSName'
curl http://<DNS>/swagger
```

Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md).

---

## 12. Limpieza

```powershell
cd I:\Curso\ShopDemo\scripts\aws
.\Remove-AwsShopDemo.ps1
```

---

## Referencia CLI AWS

- [aws ec2](https://docs.aws.amazon.com/cli/latest/reference/ec2/)
- [aws ecs](https://docs.aws.amazon.com/cli/latest/reference/ecs/)
- [aws ecr](https://docs.aws.amazon.com/cli/latest/reference/ecr/)
- [aws ssm](https://docs.aws.amazon.com/cli/latest/reference/ssm/)
