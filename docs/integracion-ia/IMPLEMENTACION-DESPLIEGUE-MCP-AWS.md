# Implementación — Despliegue MCP Gateway en AWS (ECS + EKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Componente:** `AI/ShopDemo.Mcp.Api` · **Requerimientos:** [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md)  
**Prerequisito:** APIs de negocio en ECS o EKS ([IMPLEMENTACION-DESPLIEGUE-AWS.md](../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)).

> Cada paso incluye **Consola AWS** y **CLI**.

---

## Índice

### Parte A — Amazon ECS Fargate
1. [Variables](#1-variables)
2. [Paso A1 — Repositorio ECR](#paso-a1--repositorio-ecr)
3. [Paso A2 — Build y push](#paso-a2--build-y-push)
4. [Paso A3 — Task definition](#paso-a3--task-definition)
5. [Paso A4 — Service + ALB](#paso-a4--service--alb)
6. [Paso A5 — Probar MCP en ECS](#paso-a5--probar-mcp-en-ecs)

### Parte B — Amazon EKS
7. [Paso B1 — Push imagen ECR](#paso-b1--push-imagen-ecr)
8. [Paso B2 — Manifiestos k8s/mcp](#paso-b2--manifiestos-k8smcp)
9. [Paso B3 — Ingress](#paso-b3--ingress)
10. [Paso B4 — Probar MCP en EKS](#paso-b4--probar-mcp-en-eks)

### Común
11. [Paso C1 — CI/CD GitHub Actions](#paso-c1--cicd-github-actions)
12. [Solución de problemas](#solución-de-problemas)

---

## 1. Variables

```bash
export AWS_REGION=us-east-1
export ECS_CLUSTER=shopdemo-cluster
export EKS_CLUSTER=shopdemo-eks
```

Obtener URLs/DNS de APIs ya desplegadas (ALB o Cloud Map):

```bash
# Ejemplo: DNS ALB Catalog desde Consola EC2 → Load Balancers
export CATALOG_URL=http://shopdemo-catalog-alb-xxx.us-east-1.elb.amazonaws.com
export INVENTORY_URL=http://shopdemo-inventory-alb-xxx.us-east-1.elb.amazonaws.com
export ANALYTICS_URL=http://shopdemo-analytics-alb-xxx.us-east-1.elb.amazonaws.com
```

En ECS con **Cloud Map**, usar nombres internos:

```bash
export CATALOG_URL=http://shopdemo-catalog.shopdemo.local:8080
export INVENTORY_URL=http://shopdemo-inventory.shopdemo.local:8080
export ANALYTICS_URL=http://shopdemo-analytics.shopdemo.local:8080
```

---

## Paso A1 — Repositorio ECR

**Objetivo:** Repositorio dedicado para la imagen MCP.

### Enfoque A — Consola AWS

1. **Amazon ECR** → **Create repository**
2. **Repository name:** `shopdemo-mcp`
3. **Create repository**

### Enfoque B — CLI

```bash
aws ecr create-repository \
  --repository-name shopdemo-mcp \
  --region $AWS_REGION
```

---

## Paso A2 — Build y push

### CLI

```bash
cd I:\Curso\ShopDemo
$ACCOUNT = aws sts get-caller-identity --query Account --output text
$ECR = "$ACCOUNT.dkr.ecr.$env:AWS_REGION.amazonaws.com"

aws ecr get-login-password --region $env:AWS_REGION | docker login --username AWS --password-stdin $ECR

docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t ${ECR}/shopdemo-mcp:v1 .
docker push ${ECR}/shopdemo-mcp:v1
```

**Explicación:** Mismo Dockerfile que Azure; tag `v1` o `latest` según tu convención.

---

## Paso A3 — Task definition

**Objetivo:** Definir contenedor MCP con variables y logs.

### Enfoque A — Consola AWS

1. **ECS** → **Task definitions** → **Create new task definition**
2. **Family:** `shopdemo-mcp`
3. **Launch type:** Fargate
4. **Container:**
   - Name: `mcp-api`
   - Image URI: `<account>.dkr.ecr.us-east-1.amazonaws.com/shopdemo-mcp:v1`
   - Port: `8080`
   - **Environment variables:**

| Key | Value |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ShopDemo__CatalogApiBaseUrl` | URL Catalog |
| `ShopDemo__InventoryApiBaseUrl` | URL Inventory |
| `ShopDemo__AnalyticsApiBaseUrl` | URL Analytics |

5. **Health check:** `CMD-SHELL,curl -f http://localhost:8080/health || exit 1`
6. **Log configuration:** `awslogs`, group `/ecs/shopdemo-mcp`
7. **Create**

### Enfoque B — CLI (fragmento JSON)

Registrar task definition desde JSON (ajustar ARNs y URLs):

```json
{
  "family": "shopdemo-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "mcp-api",
      "image": "<ECR>/shopdemo-mcp:v1",
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" },
        { "name": "ShopDemo__CatalogApiBaseUrl", "value": "http://..." },
        { "name": "ShopDemo__InventoryApiBaseUrl", "value": "http://..." },
        { "name": "ShopDemo__AnalyticsApiBaseUrl", "value": "http://..." }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/shopdemo-mcp",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "mcp"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    }
  ]
}
```

```bash
aws logs create-log-group --log-group-name /ecs/shopdemo-mcp --region $AWS_REGION
aws ecs register-task-definition --cli-input-json file://task-mcp.json
```

---

## Paso A4 — Service + ALB

**Objetivo:** Service Fargate con balanceador y health check en `/health`.

### Enfoque A — Consola

1. **ECS** → cluster `shopdemo-cluster` → **Create service**
2. **Task definition:** `shopdemo-mcp`
3. **Service name:** `shopdemo-mcp`
4. **Desired tasks:** 1
5. **Networking:** misma VPC/subnets/security groups que otras APIs
6. **Load balancing:** Application Load Balancer
   - Target group nuevo, health path `/health`, port 8080
7. **Create service**

### Enfoque B — CLI

```bash
aws ecs create-service \
  --cluster $ECS_CLUSTER \
  --service-name shopdemo-mcp \
  --task-definition shopdemo-mcp \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=mcp-api,containerPort=8080"
```

**Explicación:** El ALB debe apuntar health check a `/health` (matcher 200).

---

## Paso A5 — Probar MCP en ECS

```bash
# DNS del ALB MCP (Consola EC2 → Target Groups → Load balancer)
curl http://<alb-mcp-dns>/health
```

| # | Prueba | Esperado |
|---|---|---|
| 1 | Health | 200 |
| 2 | CloudWatch Logs | Grupo `/ecs/shopdemo-mcp` con stdout |
| 3 | Agente | `http://<alb-mcp-dns>/mcp` |

---

## Paso B1 — Push imagen ECR

Igual que [Paso A2](#paso-a2--build-y-push).

---

## Paso B2 — Manifiestos k8s/mcp

### CLI

```bash
aws eks update-kubeconfig --name $EKS_CLUSTER --region $AWS_REGION
$ACCOUNT = aws sts get-caller-identity --query Account --output text
$ECR_IMAGE = "$ACCOUNT.dkr.ecr.$env:AWS_REGION.amazonaws.com/shopdemo-mcp:v1"

```bash
kubectl apply -f k8s/aws/mcp/deployment.yaml
kubectl apply -f k8s/mcp/service.yaml
kubectl wait --for=condition=ready pod -l app=shopdemo-mcp -n shopdemo --timeout=120s
```

**Explicación:** En EKS las URLs internas del Deployment ya apuntan a Services cluster (`shopdemo-catalog:8080`, etc.).

---

## Paso B3 — Ingress

```bash
kubectl apply -f k8s/ingress/
kubectl get ingress -n shopdemo
```

Ruta `/mcp` definida en `k8s/ingress/ingress.yaml`.

---

## Paso B4 — Probar MCP en EKS

```bash
kubectl get pods -n shopdemo -l app=shopdemo-mcp
kubectl logs -n shopdemo -l app=shopdemo-mcp --tail=30

# Hostname del Ingress (NLB/ALB)
kubectl get ingress shopdemo-ingress -n shopdemo
curl http://<ingress-host>/mcp/health
```

Configurar agente: `http://<ingress-host>/mcp`

---

## Paso C1 — CI/CD GitHub Actions

| Workflow | MCP en |
|---|---|
| [deploy-aws.yml](../../.github/workflows/deploy-aws.yml) | ECS service `shopdemo-mcp` |
| [deploy-eks.yml](../../.github/workflows/deploy-eks.yml) | Deployment `shopdemo-mcp` + Ingress `/mcp` |

Configuración: [SETUP-GITHUB.md](../../.github/SETUP-GITHUB.md)

Fragmento ECS:

```yaml
- dockerfile: AI/ShopDemo.Mcp.Api/Dockerfile
  repository: shopdemo-mcp
  task_family: shopdemo-mcp
  container_name: mcp-api
```

### Requisitos previos

| Recurso | Debe existir antes del workflow |
|---|---|
| ECR repo `shopdemo-mcp` | Script `-Mode ECS/EKS` |
| ECS service `shopdemo-mcp` | Script o guía manual |
| Secrets GitHub | Ver [SECRETS-CHECKLIST.md](../../.github/SECRETS-CHECKLIST.md) |

---

## Solución de problemas

| Síntoma | Causa | Acción |
|---|---|---|
| Task stopped | Health check falla | CloudWatch Logs `/ecs/shopdemo-mcp` |
| Tool error | MCP no alcanza APIs | Security groups / URLs env |
| 502 ALB | Target unhealthy | Verificar `/health` en task |
| EKS ImagePullBackOff | ECR sin permiso node | Política ECR read en node role |

---

## Checklist

| # | Criterio | ECS | EKS |
|---|---|---|---|
| 1 | Imagen en ECR | ✓ | ✓ |
| 2 | `/health` 200 | ✓ | ✓ |
| 3 | Logs en CloudWatch | ✓ | ✓ (Container Insights) |
| 4 | Agente `/mcp` | ✓ | ✓ |
| 5 | CI/CD shopdemo-mcp | ✓ | ✓ ([deploy-eks.yml](../../.github/workflows/deploy-eks.yml)) |

---

## Referencias

- [k8s/mcp/](../../k8s/mcp/)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](../despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)
