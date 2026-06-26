# Guía — Release AWS con script PowerShell (recomendada)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Tiempo estimado** | 2–4 h (IAM + infra + push ECR + pruebas) |
| **Plataforma** | Amazon ECS Fargate |

**Índice del lab:** [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)  
**Alternativas:** [CLI](./GUIA-RELEASE-CLI-AWS.md) · [Portal](./GUIA-RELEASE-PORTAL-AWS.md)  
**Scripts:** [scripts/aws/](../../../scripts/aws/)

---

## Qué hace y qué NO hace el script

| Hace | No hace |
|---|---|
| ECR, VPC, SG, ECS cluster, SSM | `docker build` / `docker push` |
| Postgres + Azurite en Fargate | Crear Event Hubs (está en **Azure**) |
| Cloud Map + 5 APIs + MCP con ALB | Configurar usuario IAM (tú antes) |
| Modo EKS: cluster + `k8s/secrets.yaml` | `kubectl apply` |

---

## Paso 0 — Usuario IAM (antes del script)

AWS limita **10 políticas por usuario**. No adjuntes 8 políticas sueltas.

### Opción recomendada — 1 política custom

1. **IAM** → **Policies** → **Create policy** → JSON
2. Pegar [`scripts/aws/iam-policy-shopdemo-lab-ecs.json`](../../../scripts/aws/iam-policy-shopdemo-lab-ecs.json)
3. Nombre: `ShopDemoLabECS` → **Create**
4. **Users** → tu usuario → **Attach** `ShopDemoLabECS`  
   (Si tienes 10 políticas, **Detach** las que no uses)

### Alternativa — 2 políticas

`PowerUserAccess` + `IAMFullAccess`

Detalle: [GUIA-RELEASE-PORTAL-AWS.md § IAM](./GUIA-RELEASE-PORTAL-AWS.md#0-usuario-iam-y-permisos).

---

## Paso 1 — Variables (`.env.aws`)

```powershell
cd I:\Curso\ShopDemo\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws
```

| Variable | Valor ejemplo | Dónde |
|---|---|---|
| `AWS_REGION` | `us-east-1` | Consola / `aws configure` |
| `LAB_PREFIX` | `shopdemo` | Prefijo recursos |
| `ECS_CLUSTER_NAME` | `shopdemo-cluster` | Cluster ECS |
| `EVENT_HUBS_CONNECTION_STRING` | `Endpoint=sb://...` | **Azure Portal** → Event Hubs |
| `EVENT_HUB_NAME` | `shopdemo-events` | Fijo curso |
| `POSTGRES_PASSWORD` | `ShopDemo123!` | Tú defines |
| `IMAGE_TAG` | `latest` | Tag ECR |

Event Hubs: [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md#44-obtener-connection-string-del-namespace).

---

## Paso 2 — Credenciales AWS CLI

```powershell
aws configure
aws sts get-caller-identity
```

---

## Paso 3 — Ejecutar script

| Modo | Comando | Cuándo |
|---|---|---|
| **ECS** (recomendado) | `.\Deploy-AwsShopDemo.ps1 -Mode ECS` | Release Fargate |
| **EKS** | `.\Deploy-AwsShopDemo.ps1 -Mode EKS` | Kubernetes AWS (día aparte) |
| **All** | `.\Deploy-AwsShopDemo.ps1 -Mode All` | Ambos |

```powershell
.\Deploy-AwsShopDemo.ps1 -Mode ECS
```

**Salida:** DNS de ALB para catalog, orders, analytics, mcp; URL interna `inventory.shopdemo.local`.

Estado guardado en `scripts/aws/.deploy-state.json` (no commitear).

---

## Paso 4 — Publicar imágenes en ECR (obligatorio)

> **No se sube desde la consola AWS.** Usa Docker Desktop + AWS CLI en tu PC. Detalle Portal: [GUIA-RELEASE-PORTAL-AWS §12](./GUIA-RELEASE-PORTAL-AWS.md#12-publicar-imágenes-en-ecr).

```powershell
cd I:\Curso\ShopDemo
$region = "us-east-1"   # igual que AWS_REGION en .env.aws
$account = aws sts get-caller-identity --query Account --output text
$ecr = "$account.dkr.ecr.$region.amazonaws.com"

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ecr

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $ecr/shopdemo-catalog:latest .
docker push $ecr/shopdemo-catalog:latest

docker build -f Orders/ShopDemo.Orders.Api/Dockerfile -t $ecr/shopdemo-orders:latest .
docker push $ecr/shopdemo-orders:latest

docker build -f Inventory/ShopDemo.Inventory.Api/Dockerfile -t $ecr/shopdemo-inventory:latest .
docker push $ecr/shopdemo-inventory:latest

docker build -f Aspire/ShopDemo.Analytics.Api/Dockerfile -t $ecr/shopdemo-analytics:latest .
docker push $ecr/shopdemo-analytics:latest

docker build -f AI/ShopDemo.Mcp.Api/Dockerfile -t $ecr/shopdemo-mcp:latest .
docker push $ecr/shopdemo-mcp:latest
```

Verificar: **ECR** → cada repo debe mostrar tag `latest`.

O workflow: [.github/workflows/deploy-aws.yml](../../../.github/workflows/deploy-aws.yml)

---

## Paso 5 — Forzar redespliegue (si las tasks arrancaron sin imagen)

```powershell
aws ecs update-service --cluster shopdemo-cluster --service shopdemo-catalog --force-new-deployment
# Repetir por cada servicio
```

O espera a que GitHub Actions ejecute `force-new-deployment`.

---

## Paso 6 — Validar

```powershell
# DNS del ALB Catalog (salida del script)
curl http://<shopdemo-catalog-alb-dns>/health
```

Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md).

---

## Paso 7 — Limpieza

```powershell
.\Remove-AwsShopDemo.ps1
# Confirmar: delete-shopdemo
```

---

## Modo EKS (opcional)

Ver [GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md#eks).

---

## Solución de problemas

| Síntoma | Acción |
|---|---|
| `AccessDenied` | Política IAM — Paso 0 |
| `Cannot exceed PoliciesPerUser: 10` | Una sola política `ShopDemoLabECS` |
| Tasks en `STOPPED` | Falta push ECR — Paso 4; luego **Force new deployment** |
| ¿IP pública o privada en SSM Postgres? | **IP privada** de la task ECS — [Portal §8](./GUIA-RELEASE-PORTAL-AWS.md#8-postgresql-en-fargate) |
| `docker push` AccessDenied | IAM `ShopDemoLabECS` o repetir `docker login` ECR |
| Orders no llega a Inventory | Cloud Map `inventory.shopdemo.local` — re-ejecutar script |
| Sin eventos | `EVENT_HUBS_CONNECTION_STRING` en `.env.aws` |

---

## Referencias

- [scripts/aws/README.md](../../../scripts/aws/README.md)
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](./IMPLEMENTACION-DESPLIEGUE-AWS.md) (índice)
