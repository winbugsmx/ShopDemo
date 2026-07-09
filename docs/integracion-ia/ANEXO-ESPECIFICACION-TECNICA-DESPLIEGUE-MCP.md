# Anexo — Especificación técnica: Despliegue MCP (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

**Imagen:** `shopdemo-mcp` · **Dockerfile:** `AI/ShopDemo.Mcp.Api/Dockerfile`

---

## 1. Despliegue por plataforma

| Plataforma | Mecanismo | Entrada |
|---|---|---|
| ACA | Container App | FQDN `/mcp` |
| AKS | `k8s/azure/mcp/deployment.yaml` + Ingress | `/mcp` |
| ECS | Service + ALB | DNS ALB `/mcp` |
| EKS | `k8s/aws/mcp/deployment.yaml` + Ingress | `/mcp` |
| Minikube | `k8s/local/mcp/` + Ingress | `shopdemo.local/mcp` |

---

## 2. Manifiestos K8s

| Archivo | Alcance |
|---|---|
| `k8s/mcp/service.yaml` | Compartido |
| `k8s/azure/mcp/deployment.yaml` | Solo AKS |
| `k8s/aws/mcp/deployment.yaml` | Solo EKS |
| `k8s/local/mcp/deployment.yaml` | Solo Minikube |
| `k8s/ingress/ingress.yaml` | Ruta `/mcp` |

---

## 3. CI/CD

| Workflow | Acción |
|---|---|
| `deploy-azure.yml` | Build + push ACR + deploy ACA (incl. MCP) |
| `deploy-aws.yml` | Build + push ECR + deploy ECS (incl. MCP) |
| `deploy-aks.yml` | Manifiestos `k8s/azure/mcp/` |
| `deploy-eks.yml` | Manifiestos `k8s/aws/mcp/` |

---

## 4. Variables por entorno

| Variable | Ejemplo ACA |
|---|---|
| `ShopDemo__CatalogApiBaseUrl` | `https://catalog.<fqdn>` |
| `ShopDemo__OrdersApiBaseUrl` | `https://orders.<fqdn>` |
| `ShopDemo__InventoryApiBaseUrl` | URL interna Inventory |
| `ShopDemo__AnalyticsApiBaseUrl` | `https://analytics.<fqdn>` |

---

## 5. RNF

| ID | Requerimiento |
|---|---|
| RNF-MCP-01 | Build context desde raíz repo |
| RNF-MCP-02 | Health probe HTTP GET `/health` |
| RNF-MCP-03 | Sin OAuth/mTLS en lab básico |

---

## 6. CA-T

| ID | Criterio |
|---|---|
| CA-T-MCP-01 | `curl .../health` → 200 en ACA, ECS, AKS, EKS |
| CA-T-MCP-02 | Agente lista tools contra URL `/mcp` |
| CA-T-MCP-03 | `kubectl get pods -l app=shopdemo-mcp` → Running |
| CA-T-MCP-04 | Workflow actualiza imagen ACR/ECR |
| CA-T-MCP-05 | Ingress ruta `/mcp` en manifiesto compartido |

---

## 7. Dependencias técnicas

- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-AKS.md](../despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](../despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)
