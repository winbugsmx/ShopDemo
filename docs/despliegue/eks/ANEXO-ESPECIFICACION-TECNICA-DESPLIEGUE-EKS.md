# Anexo — Especificación técnica: Despliegue EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

**Plataforma:** EKS · **Registro:** ECR · **Manifiestos:** `k8s/` + `k8s/aws/`

---

## 1. Componentes AWS

| Recurso | Propósito |
|---|---|
| EKS cluster | 1 node group (lab) |
| ECR | 5 imágenes `shopdemo-*` |
| EBS CSI driver | PVC PostgreSQL |
| Ingress NGINX (Helm) | Entrada HTTP |
| CloudWatch | Logs container |

---

## 2. Manifiestos

| Carpeta | Contenido |
|---|---|
| `k8s/` | Compartidos: namespace, postgres, services, ingress |
| `k8s/aws/*/` | Deployments con URI ECR |
| `k8s/aws/mcp/` | MCP Gateway |

---

## 3. Matriz de despliegue

| Deployment | Imagen ECR | Probes |
|---|---|---|
| catalog | `<account>.dkr.ecr.<region>.amazonaws.com/shopdemo-catalog` | `/health`, `/alive` |
| orders | `.../shopdemo-orders` | `/health`, `/alive` |
| inventory | `.../shopdemo-inventory` | `/health`, `/alive` |
| analytics | `.../shopdemo-analytics` | `/health`, `/alive` |
| mcp | `.../shopdemo-mcp` | `/health` |

---

## 4. Scripts y CI/CD

| Artefacto | Ruta |
|---|---|
| Script | `scripts/aws/Deploy-AwsShopDemo.ps1 -Mode EKS` |
| Workflow | `.github/workflows/deploy-eks.yml` |
| Apply | `.github/scripts/apply-k8s-manifests.sh k8s aws` |

---

## 5. RNF

| ID | Requerimiento |
|---|---|
| RNF-EKS-01 | eksctl o consola para cluster |
| RNF-EKS-02 | Ingress Helm + EBS CSI obligatorios |
| RNF-EKS-03 | Event Hubs cross-cloud (mismo patrón ECS) |
| RNF-EKS-04 | Región única lab |

---

## 6. CA-T

| ID | Criterio |
|---|---|
| CA-T-EKS-01 | Nodos Ready |
| CA-T-EKS-02 | Todos pods `shopdemo` Running |
| CA-T-EKS-03 | Ingress accesible |
| CA-T-EKS-04 | ECR pull sin errores |
| CA-T-EKS-05 | Probes y HPA Catalog OK |
| CA-T-EKS-06 | Workflow `deploy-eks.yml` funcional |

---

## 7. Referencias

- [IMPLEMENTACION-DESPLIEGUE-EKS.md](./IMPLEMENTACION-DESPLIEGUE-EKS.md)
- [TEORIA-EKS.md](./TEORIA-EKS.md)
