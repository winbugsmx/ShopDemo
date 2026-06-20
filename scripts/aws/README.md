# Scripts PowerShell — Release AWS (ShopDemo)

Automatización del laboratorio AWS del curso Lite Thinking. Complementa la documentación; **no hace build** de imágenes Docker.

## Documentación de apoyo

| Tema | Documento |
|---|---|
| ECS Fargate + ALB | [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) |
| EKS + Kubernetes | [IMPLEMENTACION-DESPLIEGUE-EKS.md](../../docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |
| Event Hubs (Azure, cross-cloud) | [INTEGRACION-AZURE-EVENT-HUBS.md](../../docs/INTEGRACION-AZURE-EVENT-HUBS.md) |
| MCP Gateway | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |
| Guía de desarrollo | [GUIA-DESARROLLO-INTEGRACIONES.md](../../docs/GUIA-DESARROLLO-INTEGRACIONES.md) |
| CI/CD GitHub | [.github/workflows/deploy-aws.yml](../../.github/workflows/deploy-aws.yml) |

## Archivos

| Archivo | Función |
|---|---|
| `.env.aws.example` | Plantilla de variables |
| `Deploy-AwsShopDemo.ps1` | Provisionamiento (`-Mode ECS`, `EKS` o `All`) |
| `Remove-AwsShopDemo.ps1` | Limpieza del lab |
| `.deploy-state.json` | Estado para teardown (generado, no commitear) |

## Prerrequisitos

1. [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) + `aws configure`
2. Permisos de lab (ECS, EC2, ELB, SSM, IAM, ECR, Cloud Map)
3. **Event Hubs en Azure** — connection string en `.env.aws` (mensajería cross-cloud)
4. Modo **EKS**: [eksctl](https://eksctl.io/) y [kubectl](https://kubernetes.io/docs/tasks/tools/)
5. **Imágenes en ECR** antes de que arranquen las tareas ECS

## Valores que debes obtener o definir

### De AWS (Consola o administrador)

| Variable | Dónde |
|---|---|
| `AWS_REGION` | Barra superior Consola (ej. `us-east-1`) |
| Credenciales | IAM → Users → Security credentials → Access key (para `aws configure`) |

### De Azure Portal (Event Hubs — no se crea en AWS)

| Variable | Dónde |
|---|---|
| `EVENT_HUBS_CONNECTION_STRING` | Event Hubs namespace → Shared access policies → **RootManageSharedAccessKey** → Primary Connection String |

Ref: [INTEGRACION-AZURE-EVENT-HUBS.md](../../docs/INTEGRACION-AZURE-EVENT-HUBS.md) §4.4

### Valores que defines tú (en `.env.aws`)

| Variable | Valor ejemplo |
|---|---|
| `LAB_PREFIX` | `shopdemo` — prefijo VPC, SG, ALB, ECS |
| `ECS_CLUSTER_NAME` | `shopdemo-cluster` |
| `CLOUDMAP_NAMESPACE` | `shopdemo.local` |
| `POSTGRES_PASSWORD` | `ShopDemo123!` |
| `IMAGE_TAG` | `latest` |

### Nombres canónicos (alineados con `Deploy-AwsShopDemo.ps1`)

| Recurso | Nombre |
|---|---|
| VPC | `shopdemo-vpc` |
| Security groups | `shopdemo-alb`, `shopdemo-apps`, `shopdemo-data` |
| ALB Catalog | `shopdemo-catalog-alb` / TG `shopdemo-catalog-tg` |
| ECS services | `shopdemo-catalog`, `shopdemo-inventory`, …, `shopdemo-mcp` |
| SSM | `/shopdemo/eh-connection`, `/shopdemo/pg-catalog`, … |

### Lo que el script obtiene o crea solo

| Recurso | Cómo |
|---|---|
| ECR registry URI | `aws sts get-caller-identity` + región |
| IPs PostgreSQL / Azurite | Tasks ECS Fargate |
| Parámetros SSM | Connection strings calculadas |
| DNS ALB | Tras crear load balancers |
| `k8s/secrets.yaml` | Modo EKS (Event Hubs + Postgres in-cluster) |

## Uso rápido

> **Documentación paso a paso en el curso:** [IMPLEMENTACION-DESPLIEGUE-AWS §0](../../docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md#0-script-powershell-automatizado-recomendado) · [README principal](../../README.md#release-aws)

```powershell
cd I:\Curso\ShopDemo\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws   # EVENT_HUBS_CONNECTION_STRING + región

aws configure
aws sts get-caller-identity

.\Deploy-AwsShopDemo.ps1 -Mode ECS
# Publicar imágenes: .github/workflows/deploy-aws.yml o build manual (doc §7)

# Probar:
# http://<alb-catalog>/swagger
# http://<alb-mcp>/health

.\Remove-AwsShopDemo.ps1
```

## Modos

| Modo | Crea | No incluye |
|---|---|---|
| **ECS** | VPC, SG, ECR, SSM, cluster, Postgres/Azurite Fargate, Cloud Map, 5 APIs + MCP con ALB | Build Docker |
| **EKS** | ECR, cluster (eksctl), Ingress Helm, `k8s/secrets.yaml` | Build, `kubectl apply` |
| **All** | ECS + EKS | Build Docker |

## Checkpoints Event Hubs

| Entorno | Almacén |
|---|---|
| **ECS** | **Azurite** en Fargate (como doc AWS) → SSM `/shopdemo/azurite-checkpoint` |
| **EKS** | **Azurite** in-cluster (`k8s/azurite/`) |

Event Hubs siempre es **Azure** (cross-cloud).

## Orden recomendado

1. Crear Event Hubs en Azure (o usar namespace existente del curso)
2. `Deploy-AwsShopDemo.ps1 -Mode ECS`
3. Publicar 5 imágenes en ECR
4. Esperar tasks `RUNNING` → probar con Postman / GUIA-ENDPOINTS
5. (Opcional) `-Mode EKS` + `kubectl apply -f k8s/`

## Solución de problemas

| Síntoma | Acción |
|---|---|
| Task stopped | CloudWatch Logs `/ecs/shopdemo-*` |
| Image pull error | Publica imagen con tag `IMAGE_TAG` en ECR |
| Orders no llega a Inventory | Verificar Cloud Map `inventory.shopdemo.local` |
| Sin eventos Analytics | SG debe permitir salida HTTPS; revisar connection string EH |
| `Completa EVENT_HUBS...` | Pegar connection string de Azure en `.env.aws` |

## Seguridad

- No commitees `.env.aws`, `.deploy-state.json` ni `k8s/secrets.yaml`
- Usa IAM de lab; rota access keys tras el curso
