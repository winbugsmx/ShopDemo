# Preparación del ambiente AWS — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Propósito** | Herramientas, IAM y cuotas **antes** del release ECS o EKS |

**Guías de release:** [Script](./GUIA-RELEASE-SCRIPT-AWS.md) · [CLI](./GUIA-RELEASE-CLI-AWS.md) · [Portal](./GUIA-RELEASE-PORTAL-AWS.md)

---

## 1. Herramientas en tu PC

| Herramienta | Versión mínima | Obligatorio para | Instalación |
|---|---|---|---|
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | 2.x | ECS, EKS | `aws --version` |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 24+ | Push ECR | `docker version` |
| [eksctl](https://eksctl.io/installation/) | 0.170+ | EKS | `%LOCALAPPDATA%\eksctl\eksctl.exe` o PATH |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.28+ | EKS | `kubectl version --client` |
| [Helm](https://helm.sh/docs/intro/install/) | 3.x | EKS (opcional; perfil lab sin Ingress) | `helm version` |
| PowerShell | 5.1+ | Script | Windows nativo |

### Verificación rápida

```powershell
aws --version
aws sts get-caller-identity
docker version
kubectl version --client
eksctl version
helm version
```

---

## 2. Usuario IAM y políticas

AWS limita **10 políticas administradas por usuario**. Para el lab usa **políticas custom** en lugar de adjuntar muchas políticas sueltas.

### 2.1 Release ECS (Fargate)

| Política | Archivo | Nombre en IAM |
|---|---|---|
| **ShopDemoLabECS** | [`scripts/aws/iam-policy-shopdemo-lab-ecs.json`](../../../scripts/aws/iam-policy-shopdemo-lab-ecs.json) | `ShopDemoLabECS` |

**Permisos incluidos:** `sts`, `ecr`, `ec2`, `ecs`, `elasticloadbalancing`, `ssm`, `logs`, `servicediscovery`, `iam` (solo rol `shopdemo-ecs-execution`).

```powershell
cd I:\Curso\ShopDemo\scripts\aws

aws iam create-policy --policy-name ShopDemoLabECS `
  --policy-document file://iam-policy-shopdemo-lab-ecs.json `
  --description "ShopDemo lab ECS Fargate"

aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn arn:aws:iam::TU_ACCOUNT_ID:policy/ShopDemoLabECS
```

### 2.2 Release EKS (Kubernetes)

| Política | Archivo | Nombre en IAM |
|---|---|---|
| **ShopDemoLabEKS** | [`scripts/aws/iam-policy-shopdemo-lab-eks.json`](../../../scripts/aws/iam-policy-shopdemo-lab-eks.json) | `ShopDemoLabEKS` |

**Permisos incluidos:** `eks`, `cloudformation`, `ec2`, `logs`, `autoscaling`, `iam` (roles `eksctl-*`, `shopdemo-*`).

```powershell
aws iam create-policy --policy-name ShopDemoLabEKS `
  --policy-document file://iam-policy-shopdemo-lab-eks.json `
  --description "ShopDemo lab EKS eksctl"

aws iam attach-user-policy --user-name TU_USUARIO `
  --policy-arn arn:aws:iam::TU_ACCOUNT_ID:policy/ShopDemoLabEKS
```

### 2.3 ECS + EKS en la misma cuenta

| Enfoque | Políticas adjuntas |
|---|---|
| **Recomendado** | `ShopDemoLabECS` + `ShopDemoLabEKS` + `AmazonEC2ContainerRegistryFullAccess` (push Docker) |
| **Alternativa amplia** | `PowerUserAccess` + `IAMFullAccess` (2 políticas; cubre todo el lab) |

> En el release real del curso también se usó `AmazonEC2ContainerRegistryFullAccess`, `AmazonSSMFullAccess` y `IAMFullAccess` cuando la cuenta lo permitía. Lo mínimo funcional es **ShopDemoLabECS** + **ShopDemoLabEKS** + permiso **ECR push**.

### 2.4 Access Key para CLI

1. **IAM** → **Users** → tu usuario → **Security credentials**
2. **Create access key** → **Command Line Interface (CLI)**
3. En PC:

```powershell
aws configure
# AWS Access Key ID: ...
# AWS Secret Access Key: ...
# Default region: us-east-2   (o la región de tu lab)
# Default output: json

aws sts get-caller-identity
```

---

## 3. Cuotas y Free Tier (importante para EKS)

| Límite | Valor típico (cuenta lab) | Impacto |
|---|---|---|
| **vCPU On-Demand** | 8 vCPU | Máx. **4 nodos `t3.micro`** (2 vCPU c/u) |
| **Free Tier EC2** | 750 h/mes `t3.micro` | 4 nodos 24/7 **superan** el free tier |
| **Pods por `t3.micro`** | 4 pods/nodo | 4 nodos = **16 pods** en todo el cluster |
| **EKS control plane** | — | **No gratis** (~USD 0,10/h por cluster) |
| **Classic ELB / NLB** | — | **No gratis** (cobro por hora) |

### Tipos de instancia EKS en cuenta Free Tier

| Tipo | ¿Elegible Free Tier? | Resultado en el lab |
|---|---|---|
| `t3.micro` | **Sí** | Usar en nodegroup |
| `t3.small` / `t3.medium` | **No** (cuenta lab) | `CreateNodegroup` falla con *not eligible for Free Tier* |

---

## 4. Prerequisito cross-cloud — Azure Event Hubs

**No se crea en AWS.** Obtén la connection string antes del release:

1. [portal.azure.com](https://portal.azure.com) → namespace `shopdemo-eh-ns-lab01`
2. **Shared access policies** → **RootManageSharedAccessKey** → **Primary Connection String**
3. Guardar en `.env.aws` → `EVENT_HUBS_CONNECTION_STRING`

Ref: [INTEGRACION-AZURE-EVENT-HUBS.md](../../INTEGRACION-AZURE-EVENT-HUBS.md)

---

## 5. Archivo `.env.aws`

```powershell
cd I:\Curso\ShopDemo\scripts\aws
copy .env.aws.example .env.aws
notepad .env.aws
```

| Variable | ECS | EKS (free-tier lab) |
|---|---|---|
| `AWS_REGION` | `us-east-2` | `us-east-2` |
| `EVENT_HUBS_CONNECTION_STRING` | Azure | Azure |
| `EKS_CLUSTER_NAME` | — | `shopdemo-eks` |
| `EKS_NODE_TYPE` | — | `t3.micro` |
| `EKS_NODE_COUNT` | — | `4` |

---

## 6. Región recomendada

| Región | Uso en el curso |
|---|---|
| **`us-east-2`** (Ohio) | Release ECS + EKS validado en lab |
| `us-east-1` | Alternativa; ajusta todos los comandos |

Mantén **la misma región** en Consola, `.env.aws`, `aws configure` y `eksctl`.

---

## 7. Comandos extras útiles

```powershell
# Ver cuota vCPU
aws service-quotas get-service-quota --service-code ec2 `
  --quota-code L-1216C47A --region us-east-2

# Listar políticas adjuntas al usuario
aws iam list-attached-user-policies --user-name TU_USUARIO

# Ver cluster EKS
aws eks describe-cluster --name shopdemo-eks --region us-east-2

# Ver nodegroups
aws eks list-nodegroups --cluster-name shopdemo-eks --region us-east-2

# Pods y servicios K8s
kubectl get pods,svc -n shopdemo
```

---

## 8. Orden recomendado del lab

Elige **una** de las tres rutas (mismo resultado):

| Ruta | Documento |
|---|---|
| Script (2–4 h) | [GUIA-RELEASE-SCRIPT-AWS.md](./GUIA-RELEASE-SCRIPT-AWS.md) |
| CLI manual (10–16 h) | [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md) |
| Portal (12–20 h) | [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md) |

Pasos comunes a todas las rutas:

1. Preparar IAM + herramientas (este documento)
2. Event Hubs en Azure (connection string)
3. Build/push 5 imágenes a ECR
4. Release **ECS** o **EKS** según la guía elegida
5. (EKS) Aplicar perfil `eks-free-tier-lab`
6. Validar Swagger: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md)
