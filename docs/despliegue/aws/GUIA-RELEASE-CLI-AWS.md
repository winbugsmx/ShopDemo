# Guía — Release AWS con AWS CLI (manual)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Región lab** | `us-east-2` (Ohio) |
| **Enfoque** | **CLI** — comando por comando, sin script |

**Preparación:** [PREPARACION-AMBIENTE-AWS.md](./PREPARACION-AMBIENTE-AWS.md)  
**Otras rutas equivalentes:** [Script](./GUIA-RELEASE-SCRIPT-AWS.md) · [Portal](./GUIA-RELEASE-PORTAL-AWS.md)

> El resultado final es el **mismo** que con el script o la consola. Elige **una** ruta según tu preferencia de aprendizaje.

---

## Parte A — Release ECS (Fargate)

### A.0 Variables de sesión

```powershell
$REGION = "us-east-2"
$PREFIX = "shopdemo"
$VPC_CIDR = "10.0.0.0/16"
$CLUSTER = "shopdemo-cluster"
$IMAGE_TAG = "latest"
$ACCOUNT = (aws sts get-caller-identity --query Account --output text)
$ECR = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
```

### A.1 IAM (una vez)

```powershell
cd I:\Curso\ShopDemo\scripts\aws

aws iam create-policy --policy-name ShopDemoLabECS `
  --policy-document file://iam-policy-shopdemo-lab-ecs.json `
  --description "ShopDemo lab ECS Fargate"

aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn "arn:aws:iam::${ACCOUNT}:policy/ShopDemoLabECS"

# Push imágenes Docker a ECR (si no está en ShopDemoLabECS)
aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
```

Detalle de permisos: [PREPARACION-AMBIENTE-AWS.md §2](./PREPARACION-AMBIENTE-AWS.md#2-usuario-iam-y-políticas).

### A.2 ECR — crear repositorios

```powershell
foreach ($repo in @("shopdemo-catalog","shopdemo-orders","shopdemo-inventory","shopdemo-analytics","shopdemo-mcp")) {
  aws ecr create-repository --repository-name $repo --region $REGION 2>$null
}
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR
```

### A.3 Build y push imágenes (5 servicios)

Desde la raíz del repo `I:\Curso\ShopDemo`:

```powershell
cd I:\Curso\ShopDemo

docker build -t shopdemo-catalog:$IMAGE_TAG -f ShopDemo.Catalog.Api/Dockerfile .
docker tag shopdemo-catalog:$IMAGE_TAG "$ECR/shopdemo-catalog:$IMAGE_TAG"
docker push "$ECR/shopdemo-catalog:$IMAGE_TAG"

docker build -t shopdemo-orders:$IMAGE_TAG -f ShopDemo.Orders.Api/Dockerfile .
docker tag shopdemo-orders:$IMAGE_TAG "$ECR/shopdemo-orders:$IMAGE_TAG"
docker push "$ECR/shopdemo-orders:$IMAGE_TAG"

docker build -t shopdemo-inventory:$IMAGE_TAG -f ShopDemo.Inventory.Api/Dockerfile .
docker tag shopdemo-inventory:$IMAGE_TAG "$ECR/shopdemo-inventory:$IMAGE_TAG"
docker push "$ECR/shopdemo-inventory:$IMAGE_TAG"

docker build -t shopdemo-analytics:$IMAGE_TAG -f ShopDemo.Analytics.Api/Dockerfile .
docker tag shopdemo-analytics:$IMAGE_TAG "$ECR/shopdemo-analytics:$IMAGE_TAG"
docker push "$ECR/shopdemo-analytics:$IMAGE_TAG"

docker build -t shopdemo-mcp:$IMAGE_TAG -f ShopDemo.McpGateway/Dockerfile .
docker tag shopdemo-mcp:$IMAGE_TAG "$ECR/shopdemo-mcp:$IMAGE_TAG"
docker push "$ECR/shopdemo-mcp:$IMAGE_TAG"
```

### A.4 VPC y subnets

```powershell
$VPC_ID = aws ec2 create-vpc --cidr-block $VPC_CIDR --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$PREFIX-vpc}]" --query Vpc.VpcId --output text
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

$SUBNET_A = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone "${REGION}a" --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PREFIX-public-a}]" --query Subnet.SubnetId --output text
$SUBNET_B = aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone "${REGION}b" --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PREFIX-public-b}]" --query Subnet.SubnetId --output text
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_B --map-public-ip-on-launch

$IGW = aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$PREFIX-igw}]" --query InternetGateway.InternetGatewayId --output text
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID

$RT = aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$PREFIX-public-rt}]" --query RouteTable.RouteTableId --output text
aws ec2 create-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 associate-route-table --route-table-id $RT --subnet-id $SUBNET_A
aws ec2 associate-route-table --route-table-id $RT --subnet-id $SUBNET_B
```

### A.5 Security Groups

```powershell
$SG_ALB = aws ec2 create-security-group --group-name "$PREFIX-alb" --description "ALB" --vpc-id $VPC_ID --query GroupId --output text
aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0

$SG_APPS = aws ec2 create-security-group --group-name "$PREFIX-apps" --description "ECS apps" --vpc-id $VPC_ID --query GroupId --output text
aws ec2 authorize-security-group-ingress --group-id $SG_APPS --protocol tcp --port 8080 --source-group $SG_ALB
aws ec2 authorize-security-group-ingress --group-id $SG_APPS --protocol tcp --port 8080 --source-group $SG_APPS

$SG_DATA = aws ec2 create-security-group --group-name "$PREFIX-data" --description "Postgres Azurite" --vpc-id $VPC_ID --query GroupId --output text
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 5432 --source-group $SG_APPS
aws ec2 authorize-security-group-ingress --group-id $SG_DATA --protocol tcp --port 10000-10002 --source-group $SG_APPS
```

### A.6 SSM — Event Hubs (antes de Postgres)

Sustituye `<<<EH-CONNECTION-STRING>>>` por tu connection string de Azure Event Hubs:

```powershell
$EH = "<<<EH-CONNECTION-STRING>>>"

aws ssm put-parameter --name "/$PREFIX/eh-connection" --value $EH --type SecureString --overwrite --region $REGION
```

Los parámetros PostgreSQL y Azurite se actualizan en **A.11** con las IPs reales de Fargate.

### A.7 Cloud Map (DNS privado Inventory)

```powershell
$OP_ID = aws servicediscovery create-private-dns-namespace `
  --name "$PREFIX.local" --vpc $VPC_ID --region $REGION `
  --description "ShopDemo service discovery" `
  --query OperationId --output text

# Esperar namespace ACTIVE (~1-2 min)
do {
  Start-Sleep -Seconds 5
  $NS_STATUS = aws servicediscovery get-operation --operation-id $OP_ID --region $REGION --query "Operation.Status" --output text
} while ($NS_STATUS -eq "PENDING")

$NS_ID = aws servicediscovery get-operation --operation-id $OP_ID --region $REGION `
  --query "Operation.Targets.NAMESPACE" --output text

$INV_SD_ARN = aws servicediscovery create-service `
  --name inventory --namespace-id $NS_ID --region $REGION `
  --dns-config "NamespaceId=$NS_ID,DnsRecords=[{Type=A,TTL=10}]" `
  --health-check-custom-config FailureThreshold=1 `
  --query "Service.Arn" --output text

Write-Host "Cloud Map: inventory.$PREFIX.local -> $INV_SD_ARN"
```

### A.8 ECS — cluster y rol de ejecución

```powershell
aws ecs create-cluster --cluster-name $CLUSTER --region $REGION `
  --capacity-providers FARGATE FARGATE_SPOT `
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1

# Rol shopdemo-ecs-execution
$Trust = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
$Trust | Out-File -Encoding ascii trust-ecs.json
aws iam create-role --role-name shopdemo-ecs-execution --assume-role-policy-document file://trust-ecs.json
aws iam attach-role-policy --role-name shopdemo-ecs-execution `
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

$SsmPol = @"
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["ssm:GetParameters","ssm:GetParameter"],"Resource":"arn:aws:ssm:${REGION}:${ACCOUNT}:parameter/${PREFIX}/*"}]}
"@
$SsmPol | Out-File -Encoding ascii ssm-read.json
aws iam put-role-policy --role-name shopdemo-ecs-execution --policy-name ShopDemoSsmRead --policy-document file://ssm-read.json
Start-Sleep -Seconds 10

$EXEC_ARN = "arn:aws:iam::${ACCOUNT}:role/shopdemo-ecs-execution"
```

### A.9 PostgreSQL y Azurite en Fargate

Crear log groups y registrar task definitions (JSON en [ANEXO-TASK-DEFINITIONS-ECS.md](./ANEXO-TASK-DEFINITIONS-ECS.md) §1-2):

```powershell
foreach ($lg in @("shopdemo-postgres","shopdemo-azurite")) {
  aws logs create-log-group --log-group-name "/ecs/$lg" --region $REGION 2>$null
}

# Editar ANEXO §1-2: sustituir <EXEC_ROLE_ARN>, <AWS_REGION>, guardar como ecs-postgres.json y ecs-azurite.json
aws ecs register-task-definition --cli-input-json file://ecs-postgres.json --region $REGION
aws ecs register-task-definition --cli-input-json file://ecs-azurite.json --region $REGION

$NET = "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_DATA],assignPublicIp=ENABLED}"

aws ecs create-service --cluster $CLUSTER --service-name shopdemo-postgres `
  --task-definition shopdemo-postgres --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET --region $REGION

aws ecs create-service --cluster $CLUSTER --service-name shopdemo-azurite `
  --task-definition shopdemo-azurite --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET --region $REGION
```

### A.10 Obtener IPs y actualizar SSM

```powershell
function Get-EcsTaskIp($ServiceName) {
  for ($i = 0; $i -lt 24; $i++) {
    $task = aws ecs list-tasks --cluster $CLUSTER --service-name $ServiceName --desired-status RUNNING --region $REGION --query "taskArns[0]" --output text
    if ($task -and $task -ne "None") {
      $ip = aws ecs describe-tasks --cluster $CLUSTER --tasks $task --region $REGION `
        --query "tasks[0].attachments[0].details[?name=='privateIPv4Address'].value | [0]" --output text
      if ($ip -and $ip -ne "None") { return $ip }
    }
    Start-Sleep -Seconds 10
  }
  throw "Timeout IP para $ServiceName"
}

$PG_IP = Get-EcsTaskIp "shopdemo-postgres"
$AZ_IP = Get-EcsTaskIp "shopdemo-azurite"
Write-Host "PostgreSQL: $PG_IP | Azurite: $AZ_IP"

$PG_PASS = "ShopDemo123!"
aws ssm put-parameter --name "/$PREFIX/pg-catalog" --value "Host=$PG_IP;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=$PG_PASS" --type SecureString --overwrite --region $REGION
aws ssm put-parameter --name "/$PREFIX/pg-orders" --value "Host=$PG_IP;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=$PG_PASS" --type SecureString --overwrite --region $REGION
aws ssm put-parameter --name "/$PREFIX/pg-inventory" --value "Host=$PG_IP;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=$PG_PASS" --type SecureString --overwrite --region $REGION
aws ssm put-parameter --name "/$PREFIX/azurite-checkpoint" --value "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://${AZ_IP}:10000/devstoreaccount1;" --type SecureString --overwrite --region $REGION
```

### A.11 Crear bases de datos PostgreSQL

```powershell
$env:PGPASSWORD = $PG_PASS
psql -h $PG_IP -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoCatalog";'
psql -h $PG_IP -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoOrders";'
psql -h $PG_IP -U ShopDemo -d postgres -c 'CREATE DATABASE "ShopDemoInventory";'
Remove-Item Env:PGPASSWORD
```

> Si no tienes `psql`, usa ECS Exec o una task one-off con imagen `postgres:16-alpine`.

### A.12 Task definitions APIs

Registrar JSON del [ANEXO §3-6](./ANEXO-TASK-DEFINITIONS-ECS.md) (sustituir `<ECR_URI>`, `<ACCOUNT_ID>`, `<AWS_REGION>`, `<EXEC_ROLE_ARN>`):

```powershell
foreach ($lg in @("shopdemo-catalog","shopdemo-inventory","shopdemo-orders","shopdemo-analytics","shopdemo-mcp")) {
  aws logs create-log-group --log-group-name "/ecs/$lg" --region $REGION 2>$null
}

aws ecs register-task-definition --cli-input-json file://ecs-catalog.json --region $REGION
aws ecs register-task-definition --cli-input-json file://ecs-inventory.json --region $REGION
aws ecs register-task-definition --cli-input-json file://ecs-analytics.json --region $REGION
```

### A.13 ALB + servicio Catalog

```powershell
$TG_CATALOG = aws elbv2 create-target-group --name shopdemo-catalog-tg --protocol HTTP --port 8080 `
  --vpc-id $VPC_ID --target-type ip --health-check-path /health --region $REGION `
  --query "TargetGroups[0].TargetGroupArn" --output text

$ALB_CATALOG_ARN = aws elbv2 create-load-balancer --name shopdemo-catalog-alb --type application `
  --scheme internet-facing --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB --region $REGION `
  --query "LoadBalancers[0].LoadBalancerArn" --output text

aws elbv2 create-listener --load-balancer-arn $ALB_CATALOG_ARN --protocol HTTP --port 80 `
  --default-actions "Type=forward,TargetGroupArn=$TG_CATALOG" --region $REGION

$NET_APPS = "awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}"
$LB_CATALOG = "targetGroupArn=$TG_CATALOG,containerName=catalog-api,containerPort=8080"

aws ecs create-service --cluster $CLUSTER --service-name shopdemo-catalog `
  --task-definition shopdemo-catalog --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET_APPS --load-balancers $LB_CATALOG --region $REGION

$ALB_CATALOG_DNS = aws elbv2 describe-load-balancers --load-balancer-arns $ALB_CATALOG_ARN --region $REGION `
  --query "LoadBalancers[0].DNSName" --output text
```

### A.14 Servicio Inventory + Cloud Map (sin ALB)

```powershell
$NET_INV = "awsvpcConfiguration={subnets=[$SUBNET_A],securityGroups=[$SG_APPS],assignPublicIp=ENABLED}"
$REGISTRY = "registryArn=$INV_SD_ARN,containerName=inventory-api"

aws ecs create-service --cluster $CLUSTER --service-name shopdemo-inventory `
  --task-definition shopdemo-inventory --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET_INV --service-registries $REGISTRY --region $REGION
```

### A.15 Task definition y servicio Orders

```powershell
aws ecs register-task-definition --cli-input-json file://ecs-orders.json --region $REGION

$TG_ORDERS = aws elbv2 create-target-group --name shopdemo-orders-tg --protocol HTTP --port 8080 `
  --vpc-id $VPC_ID --target-type ip --health-check-path /health --region $REGION `
  --query "TargetGroups[0].TargetGroupArn" --output text

$ALB_ORDERS_ARN = aws elbv2 create-load-balancer --name shopdemo-orders-alb --type application `
  --scheme internet-facing --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB --region $REGION `
  --query "LoadBalancers[0].LoadBalancerArn" --output text

aws elbv2 create-listener --load-balancer-arn $ALB_ORDERS_ARN --protocol HTTP --port 80 `
  --default-actions "Type=forward,TargetGroupArn=$TG_ORDERS" --region $REGION

$LB_ORDERS = "targetGroupArn=$TG_ORDERS,containerName=orders-api,containerPort=8080"
aws ecs create-service --cluster $CLUSTER --service-name shopdemo-orders `
  --task-definition shopdemo-orders --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET_APPS --load-balancers $LB_ORDERS --region $REGION

$ALB_ORDERS_DNS = aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ORDERS_ARN --region $REGION `
  --query "LoadBalancers[0].DNSName" --output text
```

### A.16 ALB + servicio Analytics

```powershell
$TG_ANALYTICS = aws elbv2 create-target-group --name shopdemo-analytics-tg --protocol HTTP --port 8080 `
  --vpc-id $VPC_ID --target-type ip --health-check-path /health --region $REGION `
  --query "TargetGroups[0].TargetGroupArn" --output text

$ALB_ANALYTICS_ARN = aws elbv2 create-load-balancer --name shopdemo-analytics-alb --type application `
  --scheme internet-facing --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB --region $REGION `
  --query "LoadBalancers[0].LoadBalancerArn" --output text

aws elbv2 create-listener --load-balancer-arn $ALB_ANALYTICS_ARN --protocol HTTP --port 80 `
  --default-actions "Type=forward,TargetGroupArn=$TG_ANALYTICS" --region $REGION

$LB_ANALYTICS = "targetGroupArn=$TG_ANALYTICS,containerName=analytics-api,containerPort=8080"
aws ecs create-service --cluster $CLUSTER --service-name shopdemo-analytics `
  --task-definition shopdemo-analytics --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET_APPS --load-balancers $LB_ANALYTICS --region $REGION

$ALB_ANALYTICS_DNS = aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ANALYTICS_ARN --region $REGION `
  --query "LoadBalancers[0].DNSName" --output text
```

### A.17 Task definition y servicio MCP

Editar [ANEXO §7](./ANEXO-TASK-DEFINITIONS-ECS.md): sustituir `<ALB_CATALOG_DNS>` y `<ALB_ANALYTICS_DNS>` por `$ALB_CATALOG_DNS` y `$ALB_ANALYTICS_DNS`.

```powershell
aws ecs register-task-definition --cli-input-json file://ecs-mcp.json --region $REGION

$TG_MCP = aws elbv2 create-target-group --name shopdemo-mcp-tg --protocol HTTP --port 8080 `
  --vpc-id $VPC_ID --target-type ip --health-check-path /health --region $REGION `
  --query "TargetGroups[0].TargetGroupArn" --output text

$ALB_MCP_ARN = aws elbv2 create-load-balancer --name shopdemo-mcp-alb --type application `
  --scheme internet-facing --subnets $SUBNET_A $SUBNET_B --security-groups $SG_ALB --region $REGION `
  --query "LoadBalancers[0].LoadBalancerArn" --output text

aws elbv2 create-listener --load-balancer-arn $ALB_MCP_ARN --protocol HTTP --port 80 `
  --default-actions "Type=forward,TargetGroupArn=$TG_MCP" --region $REGION

$LB_MCP = "targetGroupArn=$TG_MCP,containerName=mcp-api,containerPort=8080"
aws ecs create-service --cluster $CLUSTER --service-name shopdemo-mcp `
  --task-definition shopdemo-mcp --desired-count 1 --launch-type FARGATE `
  --network-configuration $NET_APPS --load-balancers $LB_MCP --region $REGION

$ALB_MCP_DNS = aws elbv2 describe-load-balancers --load-balancer-arns $ALB_MCP_ARN --region $REGION `
  --query "LoadBalancers[0].DNSName" --output text
```

### A.18 Validación ECS

```powershell
aws ecs list-services --cluster $CLUSTER --region $REGION

Write-Host "Catalog   : http://${ALB_CATALOG_DNS}/swagger/index.html"
Write-Host "Orders    : http://${ALB_ORDERS_DNS}/swagger/index.html"
Write-Host "Analytics : http://${ALB_ANALYTICS_DNS}/api/analytics/events"
Write-Host "MCP       : http://${ALB_MCP_DNS}/health"
Write-Host "Inventory : http://inventory.shopdemo.local:8080 (interno Cloud Map)"
```

Espera 2–5 min a que los target groups pasen a **healthy**.

### A.19 Teardown ECS

```powershell
# Eliminar servicios ECS, ALB, namespace Cloud Map, VPC (orden inverso)
# O usar el script de limpieza si ejecutaste el script antes:
cd I:\Curso\ShopDemo\scripts\aws
.\Remove-AwsShopDemo.ps1
```

---

## Parte B — Release EKS (perfil eks-free-tier-lab)

Replica el release validado: **4 nodos `t3.micro`**, Catalog/Orders/Inventory con LoadBalancer y Swagger en **:8080**, sin MCP/Ingress/Analytics.

### B.0 Variables de sesión

```powershell
$REGION = "us-east-2"
$CLUSTER = "shopdemo-eks"
$NODEGROUP = "shopdemo-ng-v2"
$NODE_TYPE = "t3.micro"
$NODE_COUNT = 4
$IMAGE_TAG = "latest"
$NAMESPACE = "shopdemo"
$ACCOUNT = (aws sts get-caller-identity --query Account --output text)
$ECR = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
```

### B.1 IAM EKS (una vez)

```powershell
cd I:\Curso\ShopDemo\scripts\aws

aws iam create-policy --policy-name ShopDemoLabEKS `
  --policy-document file://iam-policy-shopdemo-lab-eks.json `
  --description "ShopDemo lab EKS eksctl"

aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn "arn:aws:iam::${ACCOUNT}:policy/ShopDemoLabEKS"
```

También necesitas permiso ECR push (`ShopDemoLabECS` o `AmazonEC2ContainerRegistryFullAccess`).

### B.2 ECR + imágenes

Repetir **A.2** y **A.3** (mismos 5 repos e imágenes).

### B.3 Crear cluster EKS + nodegroup

```powershell
eksctl create cluster `
  --name $CLUSTER `
  --region $REGION `
  --nodegroup-name $NODEGROUP `
  --node-type $NODE_TYPE `
  --nodes $NODE_COUNT `
  --managed
```

**Si falla** por Free Tier con `t3.medium`, usa `t3.micro`.  
**Si el nodegroup anterior está en rollback**, elimínalo y crea uno nuevo:

```powershell
eksctl delete nodegroup --cluster $CLUSTER --name shopdemo-ng --region $REGION
eksctl create nodegroup --cluster $CLUSTER --name shopdemo-ng-v2 --node-type t3.micro --nodes 4 --region $REGION
```

### B.4 Configurar kubectl

```powershell
aws eks update-kubeconfig --name $CLUSTER --region $REGION
kubectl get nodes
```

### B.5 Escalar nodegroup (máximo lab)

```powershell
eksctl scale nodegroup `
  --cluster $CLUSTER `
  --name $NODEGROUP `
  --nodes 4 --nodes-min 1 --nodes-max 4 `
  --region $REGION
```

### B.6 Namespace y secrets (manual, sin script)

```powershell
kubectl apply -f I:\Curso\ShopDemo\k8s\namespace.yaml
```

Crear `I:\Curso\ShopDemo\k8s\secrets.yaml` (copiar desde `k8s/secrets.example.yaml`):

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

```powershell
kubectl apply -f I:\Curso\ShopDemo\k8s\secrets.yaml
```

> **No commitees** `k8s/secrets.yaml`.

### B.7 Actualizar imágenes ECR en manifiestos

```powershell
cd I:\Curso\ShopDemo

kubectl set image deployment/shopdemo-catalog catalog-api="${ECR}/shopdemo-catalog:${IMAGE_TAG}" -n shopdemo
kubectl set image deployment/shopdemo-orders orders-api="${ECR}/shopdemo-orders:${IMAGE_TAG}" -n shopdemo
kubectl set image deployment/shopdemo-inventory inventory-api="${ECR}/shopdemo-inventory:${IMAGE_TAG}" -n shopdemo
```

O verifica que `k8s/catalog/deployment.yaml` (y orders/inventory) ya referencian `${ECR}/shopdemo-*:latest`.

### B.8 Aplicar manifiestos (orden)

```powershell
cd I:\Curso\ShopDemo

kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/deployment.yaml
kubectl apply -f k8s/azurite/service.yaml
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/inventory/
# NO aplicar mcp/ ni ingress/ en perfil free-tier
# kubectl apply -f k8s/analytics/   # opcional; escalar a 0 después
```

### B.9 Job init checkpoints Azurite

```powershell
kubectl apply -f k8s/azurite/init-checkpoints-job.yaml
kubectl wait --for=condition=complete job/shopdemo-azurite-init-checkpoints -n shopdemo --timeout=120s
```

### B.10 Ajustes free-tier (liberar pods)

```powershell
kubectl scale deployment coredns -n kube-system --replicas=1
kubectl delete deployment shopdemo-mcp -n shopdemo --ignore-not-found
kubectl delete deployment ingress-nginx-controller -n ingress-nginx --ignore-not-found
kubectl scale deployment shopdemo-analytics -n shopdemo --replicas=0
kubectl delete hpa shopdemo-catalog-hpa -n shopdemo --ignore-not-found
```

### B.11 Verificar pods

```powershell
kubectl get pods -n shopdemo -o wide
kubectl get pods -n kube-system
```

Esperado (5 pods en `shopdemo`):

| Pod | Estado |
|---|---|
| shopdemo-postgres-0 | Running |
| shopdemo-azurite-* | Running |
| shopdemo-catalog-* | Running |
| shopdemo-orders-* | Running |
| shopdemo-inventory-* | Running |

### B.12 Obtener LoadBalancers y probar Swagger

```powershell
kubectl get svc -n shopdemo
```

Anotar `EXTERNAL-IP` de `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`.

```powershell
$CATALOG_LB = (kubectl get svc shopdemo-catalog -n shopdemo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl "http://${CATALOG_LB}:8080/swagger/index.html"
```

| API | URL |
|---|---|
| Catalog | `http://<LB-catalog>:8080/swagger/index.html` |
| Orders | `http://<LB-orders>:8080/swagger/index.html` |
| Inventory | `http://<LB-inventory>:8080/swagger/index.html` |

> **Importante:** Classic ELB expone el puerto del Service (**8080**). Sin `:8080` obtendrás timeout.

### B.13 Comandos de diagnóstico

```powershell
kubectl describe pod -n shopdemo -l app=shopdemo-catalog
kubectl logs -n shopdemo -l app=shopdemo-inventory --tail=50
aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=$CLUSTER" --region $REGION --query "Reservations[].Instances[].InstanceType"
kubectl top nodes   # requiere metrics-server
```

### B.14 Teardown EKS

```powershell
eksctl delete cluster --name $CLUSTER --region $REGION
# Elimina nodegroups, ELB huérfanos y stacks CloudFormation de eksctl
```

---

## Parte C — Comandos extras transversales

### C.1 Verificar identidad y región

```powershell
aws sts get-caller-identity
aws configure get region
```

### C.2 Listar recursos del lab

```powershell
aws ecs list-clusters --region us-east-2
aws eks list-clusters --region us-east-2
aws ecr describe-repositories --region us-east-2 --query "repositories[].repositoryName"
aws elbv2 describe-load-balancers --region us-east-2
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=shopdemo-vpc" --region us-east-2
```

### C.3 Políticas IAM adjuntas

```powershell
aws iam list-attached-user-policies --user-name TU_USUARIO
aws iam get-policy --policy-arn arn:aws:iam::TU_ACCOUNT:policy/ShopDemoLabECS
aws iam get-policy --policy-arn arn:aws:iam::TU_ACCOUNT:policy/ShopDemoLabEKS
```

### C.4 Cuota vCPU

```powershell
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A --region us-east-2
```

---

## Referencias

| Documento | Contenido |
|---|---|
| [PREPARACION-AMBIENTE-AWS.md](./PREPARACION-AMBIENTE-AWS.md) | IAM, herramientas, cuotas |
| [GUIA-RELEASE-SCRIPT-AWS.md](./GUIA-RELEASE-SCRIPT-AWS.md) | Automatización PowerShell |
| [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md) | Consola web |
| [IMPLEMENTACION-DESPLIEGUE-AWS.md](./IMPLEMENTACION-DESPLIEGUE-AWS.md) | Arquitectura ECS detallada |
