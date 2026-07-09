# Anexo — Especificación técnica: Despliegue AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Especificación técnica |

**Plataforma:** AKS · **Registro:** ACR · **Manifiestos:** `k8s/` + `k8s/azure/`

---

## 1. Componentes Azure

| Recurso | Propósito |
|---|---|
| AKS cluster | 1 node pool (lab) |
| ACR | Imágenes `shopdemo-*` |
| ACR-aks attach | Pull autenticado |
| Ingress NGINX (Helm) | Punto de entrada |
| Log Analytics | (opcional) diagnósticos cluster |

---

## 2. Manifiestos

| Carpeta | Contenido |
|---|---|
| `k8s/` | Namespace, postgres, azurite, services, ingress, HPA |
| `k8s/azure/catalog/` etc. | Deployments con URI ACR |
| `k8s/azure/mcp/` | Deployment MCP |
| `k8s/secrets.yaml` | Generado; **no commitear** |

---

## 3. Matriz de despliegue

| Deployment | Imagen | Réplicas lab | Probes |
|---|---|---|---|
| catalog | `<acr>.azurecr.io/shopdemo-catalog` | 1+ | `/health`, `/alive` |
| orders | `.../shopdemo-orders` | 1+ | `/health`, `/alive` |
| inventory | `.../shopdemo-inventory` | 1+ | `/health`, `/alive` |
| analytics | `.../shopdemo-analytics` | 1+ | `/health`, `/alive` |
| mcp | `.../shopdemo-mcp` | 1+ | `/health` |

---

## 4. Scripts y CI/CD

| Artefacto | Ruta |
|---|---|
| Script AKS | `scripts/azure/Deploy-AzureShopDemo.ps1 -Mode AKS` |
| Workflow | `.github/workflows/deploy-aks.yml` |
| Apply script | `.github/scripts/apply-k8s-manifests.sh k8s azure` |

---

## 5. RNF

| ID | Requerimiento |
|---|---|
| RNF-AKS-01 | Ingress vía Helm (no addon Minikube) |
| RNF-AKS-02 | PostgreSQL StatefulSet en cluster (no Azure Database) |
| RNF-AKS-03 | HPA Catalog como demo |
| RNF-AKS-04 | Key Vault / External Secrets fuera de alcance básico |

---

## 6. CA-T

| ID | Criterio |
|---|---|
| CA-T-AKS-01 | `kubectl get nodes` — Ready |
| CA-T-AKS-02 | 5 Deployments + Postgres StatefulSet Running |
| CA-T-AKS-03 | Ingress IP externa responde |
| CA-T-AKS-04 | ACR vinculado; pull sin ImagePullBackOff |
| CA-T-AKS-05 | Probes y HPA Catalog operativos |
| CA-T-AKS-06 | Workflow `deploy-aks.yml` aplica manifiestos |

---

## 7. Referencias

- [IMPLEMENTACION-DESPLIEGUE-AKS.md](./IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [TEORIA-AKS.md](./TEORIA-AKS.md)
- [k8s/README.md](../../../k8s/README.md)
