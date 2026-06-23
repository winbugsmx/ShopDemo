# Guía — Release AWS con Consola (visual)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Tiempo estimado** | 12–20 h (manual completo) |
| **Propósito** | Documento para **capturas de pantalla** y clase presencial |

**Ruta rápida:** [GUIA-RELEASE-SCRIPT-AWS.md](./GUIA-RELEASE-SCRIPT-AWS.md)  
**Comandos equivalentes:** [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md)

> Sustituye `[📷 Captura: …]` por imágenes en `docs/despliegue/aws/imagenes/` (carpeta opcional del instructor).

---

## 0. Usuario IAM y permisos

**Para qué sirve:** tu usuario necesita permisos para crear VPC, ECS, ALB, ECR, SSM, Cloud Map e IAM (rol de ejecución ECS).

**Documentación:** [Create IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) · [Create customer managed policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create-console.html)

### Opción recomendada — 1 política custom

| Paso | Acción |
|---|---|
| 1 | **IAM** → **Policies** → **Create policy** → **JSON** |
| 2 | Pegar [`scripts/aws/iam-policy-shopdemo-lab-ecs.json`](../../../scripts/aws/iam-policy-shopdemo-lab-ecs.json) |
| 3 | Name: `ShopDemoLabECS` → **Create policy** |
| 4 | **Users** → tu usuario → **Add permissions** → **Attach** `ShopDemoLabECS` |
| 5 | Si error `PoliciesPerUser: 10` → **Detach** políticas viejas primero |

[📷 Captura: Create policy JSON]  
[📷 Captura: Usuario con ShopDemoLabECS adjunta]

### Access Key para CLI

| Paso | Acción |
|---|---|
| 1 | Usuario → **Security credentials** → **Create access key** → **CLI** |
| 2 | En PC: `aws configure` + `aws sts get-caller-identity` |

[📷 Captura: Access key creada]

**Alternativa (2 políticas):** `PowerUserAccess` + `IAMFullAccess`.

---

## 1. Región y consola

1. Abrir [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Región: **US East (N. Virginia)** `us-east-1` (barra superior)

[📷 Captura: Consola AWS con región us-east-1]

---

## 2. Event Hubs (Azure — prerequisito cross-cloud)

**No se crea en AWS.** Obtén la connection string en Azure:

**Documentación Azure:** [Event Hubs connection string](https://learn.microsoft.com/azure/event-hubs/event-hubs-get-connection-string)

| Paso | Acción |
|---|---|
| 1 | [portal.azure.com](https://portal.azure.com) → Event Hubs namespace `shopdemo-eh-ns-lab01` |
| 2 | **Shared access policies** → **RootManageSharedAccessKey** → copiar connection string |
| 3 | Guardar para SSM `/shopdemo/eh-connection` o `.env.aws` |

[📷 Captura: Connection string Event Hubs]

---

## 3. Amazon ECR

**Para qué sirve:** registro privado de las 5 imágenes Docker.

**Documentación:** [Create private repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html)

| Paso | Acción |
|---|---|
| 1 | **Amazon ECR** → **Create repository** |
| 2 | Crear 5 repos privados: `shopdemo-catalog`, `shopdemo-orders`, `shopdemo-inventory`, `shopdemo-analytics`, `shopdemo-mcp` |

[📷 Captura: Lista de 5 repositorios ECR]

---

## 4. VPC

**Para qué sirve:** red para Fargate, ALB y DNS interno (Cloud Map).

**Documentación:** [Create a VPC](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html#create-vpc-and-other-resources)

| Paso | Acción |
|---|---|
| 1 | **VPC** → **Create VPC** → **VPC and more** |
| 2 | Name: `shopdemo-vpc` · CIDR `10.0.0.0/16` |
| 3 | 2 AZ · 2 subnets **públicas** · IGW **Sí** · NAT **No** |
| 4 | Anotar `vpc-id`, subnet IDs |

[📷 Captura: VPC wizard completado]

---

## 5. Security Groups

**Documentación:** [Security groups](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-security-groups.html)

| SG | Inbound |
|---|---|
| `shopdemo-alb` | HTTP 80 desde `0.0.0.0/0` |
| `shopdemo-apps` | TCP 8080 desde SG ALB + desde mismo SG |
| `shopdemo-data` | TCP 5432, 10000 desde SG apps |

[📷 Captura: Reglas shopdemo-apps]  
[📷 Captura: Reglas shopdemo-data]

---

## 6. Systems Manager Parameter Store

**Para qué sirve:** secretos fuera de las task definitions.

**Documentación:** [Create a parameter](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-su-create.html)

| Parámetro (SecureString) | Contenido |
|---|---|
| `/shopdemo/eh-connection` | Connection string Event Hubs |
| `/shopdemo/pg-catalog` | Connection string PostgreSQL Catalog |
| `/shopdemo/pg-orders` | Connection string Orders |
| `/shopdemo/pg-inventory` | Connection string Inventory |
| `/shopdemo/azurite-checkpoint` | Connection string Azurite Blob |

[📷 Captura: Parámetro SecureString /shopdemo/eh-connection]

---

## 7. ECS Cluster

**Documentación:** [Creating a cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-cluster-console-v2.html)

| Paso | Acción |
|---|---|
| 1 | **ECS** → **Clusters** → **Create cluster** |
| 2 | Name: `shopdemo-cluster` · Infrastructure: **AWS Fargate** |

[📷 Captura: Cluster shopdemo-cluster]

---

## 8. PostgreSQL en Fargate

**Documentación:** [Creating a task definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html) · [Creating a service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-service-console-v2.html)

| Paso | Acción |
|---|---|
| 1 | Task definition family `shopdemo-postgres` — imagen `postgres:16-alpine` |
| 2 | Service en subnets públicas, SG `shopdemo-data` |
| 3 | Crear bases `ShopDemoCatalog`, `ShopDemoOrders`, `ShopDemoInventory` |
| 4 | Actualizar parámetros SSM con host/IP real |

[📷 Captura: Service postgres RUNNING]

---

## 9. Azurite en Fargate

**Para qué sirve:** emulador Blob para checkpoints Event Hubs (en Azure ACA se usa Storage Account).

| Paso | Acción |
|---|---|
| 1 | Task family `shopdemo-azurite` — imagen Azurite |
| 2 | Service en SG `shopdemo-data` |
| 3 | Actualizar `/shopdemo/azurite-checkpoint` |

[📷 Captura: Service azurite RUNNING]

---

## 10. AWS Cloud Map

**Para qué sirve:** DNS privado `inventory.shopdemo.local` para que Orders llame a Inventory.

**Documentación:** [Creating a namespace](https://docs.aws.amazon.com/cloud-map/latest/dg/creating-namespaces.html)

| Paso | Acción |
|---|---|
| 1 | **Cloud Map** → **Create namespace** → DNS private → `shopdemo.local` |
| 2 | **Create service** → name `inventory` |
| 3 | Asociar al ECS service Inventory |

[📷 Captura: Namespace shopdemo.local + servicio inventory]

---

## 11. Application Load Balancer + APIs

**Documentación:** [ALB getting started](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancer-getting-started.html)

### Por cada API pública (Catalog, Orders, Analytics, MCP)

| Paso | Acción |
|---|---|
| 1 | **EC2** → **Load Balancers** → **Create** → **Application Load Balancer** |
| 2 | Name ej. `shopdemo-catalog-alb` · Internet-facing · subnets públicas · SG `shopdemo-alb` |
| 3 | Target group `shopdemo-catalog-tg` — puerto 8080, health `/health` |
| 4 | Listener HTTP:80 → forward al TG |
| 5 | ECS service con tipo **REPLICA**, attach al TG |

**Inventory:** sin ALB — solo Cloud Map.

[📷 Captura: ALB catalog con targets healthy]  
[📷 Captura: ECS service catalog con load balancer]

---

## 12. Publicar imágenes ECR

**Documentación:** [Pushing an image](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)

ECR → repo → **View push commands** (login, build, tag, push × 5).

[📷 Captura: Push commands en consola ECR]

---

## 13. Validación

| Comprobación | Dónde |
|---|---|
| DNS del ALB Catalog | EC2 → Load Balancers → abrir `/swagger` |
| Logs | CloudWatch → Log groups `/ecs/shopdemo-*` |
| Orders → Inventory | Logs Orders sin error de DNS |

[📷 Captura: Swagger Catalog vía DNS ALB]

---

## 14. Limpieza

ECS → detener services → eliminar cluster → ALB → ECR → SSM → VPC.

O script: `.\Remove-AwsShopDemo.ps1`

[📷 Captura: Confirmación delete cluster]

---

## Servicios que puedes omitir en lab corto

| Servicio | ¿Obligatorio en release ECS? |
|---|---|
| NAT Gateway | **No** — lab usa subnets públicas |
| EKS | **No** — otro día ([GUIA-RELEASE-KUBERNETES.md](../kubernetes/GUIA-RELEASE-KUBERNETES.md)) |
| Secrets Manager | **No** — usamos SSM Parameter Store |
| EFS | **No** — Postgres en Fargate sin volumen persistente (lab) |
