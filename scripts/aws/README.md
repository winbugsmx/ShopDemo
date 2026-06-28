# Scripts PowerShell — Release AWS (ShopDemo)

Automatización del laboratorio AWS del curso Lite Thinking. Complementa la documentación; **no hace build** de imágenes Docker.

## Documentación de apoyo

| Tema | Documento |
|---|---|
| **Script + IAM (recomendado)** | [GUIA-RELEASE-SCRIPT-AWS.md](../../docs/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) |
| Preparación IAM/cuotas | [PREPARACION-AMBIENTE-AWS.md](../../docs/despliegue/aws/PREPARACION-AMBIENTE-AWS.md) |
| Consola visual + IAM | [GUIA-RELEASE-PORTAL-AWS.md](../../docs/despliegue/aws/GUIA-RELEASE-PORTAL-AWS.md) |
| AWS CLI manual | [GUIA-RELEASE-CLI-AWS.md](../../docs/despliegue/aws/GUIA-RELEASE-CLI-AWS.md) |
| EKS + Kubernetes | [GUIA-RELEASE-KUBERNETES.md](../../docs/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |
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
2. **Usuario IAM** con permisos del lab — ver [GUIA-RELEASE-PORTAL-AWS §0](../../docs/despliegue/aws/GUIA-RELEASE-PORTAL-AWS.md#0-usuario-iam-y-permisos)
3. **Event Hubs en Azure** — connection string en `.env.aws` (mensajería cross-cloud)
4. Para modo **EKS**: [eksctl](https://eksctl.io/) y [kubectl](https://kubernetes.io/docs/tasks/tools/)
5. **Imágenes en ECR** antes de que arranquen las tareas ECS

### Resumen IAM

| Modo | Política | Archivo JSON |
|---|---|---|
| ECS | `ShopDemoLabECS` | [iam-policy-shopdemo-lab-ecs.json](iam-policy-shopdemo-lab-ecs.json) |
| EKS | `ShopDemoLabEKS` | [iam-policy-shopdemo-lab-eks.json](iam-policy-shopdemo-lab-eks.json) |

Detalle completo: [PREPARACION-AMBIENTE-AWS.md](../../docs/despliegue/aws/PREPARACION-AMBIENTE-AWS.md)

## Valores que debes obtener o definir

### De AWS (Consola o administrador)

| Variable | Dónde |
|---|---|
| `AWS_REGION` | Barra superior Consola (ej. `us-east-2`) |
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

> **Documentación:** [GUIA-RELEASE-SCRIPT-AWS](../../docs/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) · [README principal](../../README.md#release-aws)

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
| **EKS** | ECR, cluster (eksctl), Ingress Helm, `k8s/secrets.yaml`, kubectl apply base | Perfil free-tier (ajustes manuales), Build Docker |
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
5. (Opcional) `-Mode EKS` + perfil [eks-free-tier-lab](../../docs/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md#6-perfil-eks-eks-free-tier-lab-ajustes-post-script)

## Solución de problemas

| Síntoma | Acción |
|---|---|
| Task stopped | CloudWatch Logs `/ecs/shopdemo-*` |
| Image pull error | Publica imagen con tag `IMAGE_TAG` en ECR |
| Orders no llega a Inventory | Verificar Cloud Map `inventory.shopdemo.local` |
| Sin eventos Analytics | SG debe permitir salida HTTPS; revisar connection string EH |
| EKS: pods Pending | Límite 16 pods (4× t3.micro); quitar MCP/Ingress/Analytics |
| EKS: Swagger timeout | Usar puerto **:8080** en URL del Classic ELB |
| EKS: Free Tier instance | Usar `t3.micro`, no `t3.medium` |
| `Completa EVENT_HUBS...` | Pegar connection string de Azure en `.env.aws` |

## Seguridad

- No commitees `.env.aws`, `.deploy-state.json` ni `k8s/secrets.yaml`
- Usa IAM de lab; rota access keys tras el curso
