# Implementación — Despliegue AWS (índice)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Plataforma** | ECS Fargate + ECR + ALB + Cloud Map |
| **Alcance lab** | [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md) |

> La documentación paso a paso se dividió en **tres guías**. Para el release en 2–4 h usa la guía **Script**.

---

## Guías de release (elige una ruta)

| Guía | Tiempo | Cuándo usarla |
|---|---|---|
| [**GUIA-RELEASE-SCRIPT-AWS**](./GUIA-RELEASE-SCRIPT-AWS.md) | 2–4 h | **Recomendada** — `Deploy-AwsShopDemo.ps1` + IAM |
| [**GUIA-RELEASE-CLI-AWS**](./GUIA-RELEASE-CLI-AWS.md) | 10–16 h | Mismos recursos con `aws` |
| [**GUIA-RELEASE-PORTAL-AWS**](./GUIA-RELEASE-PORTAL-AWS.md) | 12–20 h | Consola visual + capturas + enlaces AWS Docs |

**Scripts:** [scripts/aws/](../../../scripts/aws/) · **IAM:** [`iam-policy-shopdemo-lab-ecs.json`](../../../scripts/aws/iam-policy-shopdemo-lab-ecs.json)  
**Task definitions:** [ANEXO-TASK-DEFINITIONS-ECS.md](./ANEXO-TASK-DEFINITIONS-ECS.md)

**Kubernetes (EKS):** [GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md)

---

## Servicios AWS del release

| Componente ShopDemo | Servicio AWS |
|---|---|
| Imágenes Docker | **ECR** (5 repos) |
| Cómputo APIs | **ECS Fargate** |
| HTTP público | **ALB** (uno por API pública) |
| DNS interno Inventory | **Cloud Map** (`inventory.shopdemo.local`) |
| Secretos | **SSM Parameter Store** (`/shopdemo/*`) |
| Red | **VPC** + Security Groups |
| Mensajería | **Azure Event Hubs** (cross-cloud) |
| Checkpoints | **Azurite** en Fargate |

---

## Convención de nombres

> Variables en `scripts/aws/.env.aws.example` · prefijo `LAB_PREFIX=shopdemo`

| Recurso AWS | Nombre canónico |
|---|---|
| Región | `us-east-1` |
| VPC | `shopdemo-vpc` |
| Security Groups | `shopdemo-alb`, `shopdemo-apps`, `shopdemo-data` |
| ECR repos | `shopdemo-catalog` … `shopdemo-mcp` |
| SSM | `/shopdemo/eh-connection`, `/shopdemo/pg-*`, … |
| ECS cluster | `shopdemo-cluster` |
| Postgres / Azurite | `shopdemo-postgres`, `shopdemo-azurite` |
| Cloud Map | `shopdemo.local` / servicio `inventory` |
| ALB | `shopdemo-catalog-alb`, `shopdemo-orders-alb`, … |

---

## IAM — resumen

| Opción | Políticas | Cuándo |
|---|---|---|
| **D (recomendada)** | 1 × `ShopDemoLabECS` (JSON en repo) | Error `PoliciesPerUser: 10` o lab limpio |
| **E** | `PowerUserAccess` + `IAMFullAccess` | Sin crear policy custom |
| **A** | 8 managed policies | Solo si tienes cupo libre |

Detalle paso a paso: [GUIA-RELEASE-PORTAL-AWS §0](./GUIA-RELEASE-PORTAL-AWS.md#0-usuario-iam-y-permisos) · [GUIA-RELEASE-SCRIPT-AWS §0](./GUIA-RELEASE-SCRIPT-AWS.md)

**Distinto del rol ECS:** el script crea `shopdemo-ecs-execution` para que Fargate lea ECR y SSM.

---

## Servicios obligatorios vs opcionales

| Servicio | ¿Obligatorio ECS? | Notas |
|---|---|---|
| IAM usuario + policy | Sí | Antes del script |
| ECR, VPC, SG, ECS, SSM | Sí | Script |
| Postgres + Azurite Fargate | Sí (lab) | Script |
| Cloud Map + 4 ALB + MCP | Sí | Script |
| NAT Gateway | **No** | Subnets públicas |
| Secrets Manager | **No** | Usamos SSM |
| EFS | **No** | Lab sin volumen persistente |
| EKS | **No** | Modo `-Mode EKS` otro día |

---

## Solución de problemas

| Síntoma | Causa | Solución |
|---|---|---|
| Task stopped immediately | Imagen o puerto | CloudWatch Logs |
| Orders no alcanza Inventory | Cloud Map | Verificar `inventory.shopdemo.local` |
| Sin eventos | Egress bloqueado | SG: salida 443 a internet |
| Health check falla | Ruta incorrecta | `/health` o `/swagger` |
| Pull ECR denied | Task execution role | `AmazonECSTaskExecutionRolePolicy` |
| `PoliciesPerUser: 10` | Demasiadas políticas IAM | Usar `ShopDemoLabECS` (1 policy) |
| ¿IP pública o privada en SSM Postgres? | Confusión de red VPC | Usar **IP privada** de la task — [Portal §8](./GUIA-RELEASE-PORTAL-AWS.md#8-postgresql-en-fargate) |
| IP Postgres cambió | Task reiniciada | Actualizar `/shopdemo/pg-*` en SSM |
| Atorado en push ECR | Push es desde PC, no Portal | [Portal §12](./GUIA-RELEASE-PORTAL-AWS.md#12-publicar-imágenes-en-ecr) |
| Event Hubs pendiente | Azure no configurado aún | Avanzar AWS; completar `/shopdemo/eh-connection` después |

---

## Referencias

- [TEORIA-CONTENEDORES-AWS.md](./TEORIA-CONTENEDORES-AWS.md)
- [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./REQUERIMIENTOS-DESPLIEGUE-AWS.md)
- [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)
- [GUIA-DESARROLLO-INTEGRACIONES.md](../../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 8)
