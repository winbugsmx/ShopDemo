# Guía — Release en Kubernetes (Minikube, AKS, EKS)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Objetivo** | Elegir **una** ruta K8s según tiempo y nube |

**Alcance del lab:** [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)

---

## ¿Qué ruta elegir?

| Ruta | Tiempo | Costo cloud | Cuándo |
|---|---|---|---|
| **Minikube local** | ~4 h | $0 | Entender manifiestos `k8s/` sin pagar nube |
| **AKS** (Azure) | +2–3 h tras ACA | Sí | Ya hiciste release ACA con script |
| **EKS** (AWS) | +2–3 h tras ECS | Sí | Ya hiciste release ECS con script |

**No es obligatorio** hacer Minikube + AKS + EKS en el mismo alumno. Para un lab de 2 días con pocas horas: **ACA o ECS con script** + opcional **Minikube**.

---

## Manifiestos comunes (`k8s/`)

| Carpeta | Contenido |
|---|---|
| `k8s/postgres/` | PostgreSQL |
| `k8s/azurite/` | Checkpoints Event Hubs |
| `k8s/catalog/`, `orders/`, `inventory/`, `analytics/` | APIs |
| `k8s/mcp/` | MCP Gateway |
| `k8s/ingress/` | Ingress NGINX |
| `k8s/secrets.example.yaml` | Plantilla → copiar a `secrets.yaml` (no commitear) |

Checkpoints en K8s: **Azurite** (no Storage Account de Azure).

---

## Ruta 1 — Minikube (recomendada para aprender K8s)

**Guía detallada:** [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md)

### Resumen en 6 pasos

```bash
minikube start --cpus 4 --memory 8192
minikube addons enable ingress

eval $(minikube docker-env)   # Linux/macOS
# Windows PowerShell: minikube docker-env | Invoke-Expression

cd I:\Curso\ShopDemo
# build 5 imágenes con tag local (ver IMPLEMENTACION-KUBERNETES-LOCAL §5)

copy k8s\secrets.example.yaml k8s\secrets.yaml
# Editar connection strings Event Hubs y PostgreSQL

kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl apply -f k8s/catalog/ -f k8s/inventory/ -f k8s/orders/ -f k8s/analytics/ -f k8s/mcp/
kubectl apply -f k8s/ingress/

minikube ip   # o minikube tunnel para LoadBalancer
```

**Teoría:** [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md)

---

## Ruta 2 — AKS (Azure)

**Prerequisito:** Event Hubs + imágenes en ACR (release ACA o script previo).

### Con script (recomendado)

```powershell
cd I:\Curso\ShopDemo\scripts\azure
.\Deploy-AzureShopDemo.ps1 -Mode AKS
# Crea cluster AKS, Ingress Helm, secrets base

kubectl apply -f k8s/
```

**Guía detallada:** [../aks/IMPLEMENTACION-DESPLIEGUE-AKS.md](../aks/IMPLEMENTACION-DESPLIEGUE-AKS.md)

### Servicios Azure que toca AKS

| Servicio | ¿Script? |
|---|---|
| ACR (imágenes) | Sí (modo ACA/AKS) |
| AKS cluster | Sí (`-Mode AKS`) |
| Event Hubs | Sí o previo |
| Log Analytics | Sí |
| **Container Apps** | No necesario en modo solo AKS |

---

## Ruta 3 — EKS (AWS)

**Prerequisito:** Imágenes en ECR + Event Hubs connection string.

### Con script (recomendado)

```powershell
cd I:\Curso\ShopDemo\scripts\aws
.\Deploy-AwsShopDemo.ps1 -Mode EKS
# eksctl + Ingress + k8s/secrets.yaml plantilla

kubectl apply -f k8s/
```

**Guía detallada:** [../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md](../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)

### Servicios AWS que toca EKS

| Servicio | ¿Script? |
|---|---|
| ECR | Sí |
| EKS cluster (eksctl) | Sí (`-Mode EKS`) |
| **ECS / ALB / Cloud Map** | No necesario en modo solo EKS |

---

## Comparación rápida

| Tema | Minikube | AKS | EKS |
|---|---|---|---|
| Ingress | Addon NGINX | Helm NGINX | Helm NGINX |
| Imágenes | Build local | ACR | ECR |
| Secretos | `k8s/secrets.yaml` | Igual | Igual |
| Checkpoints | Azurite in-cluster | Azurite | Azurite |
| Costo | Gratis | Pago por cluster | Pago por cluster |

---

## Validación

1. `kubectl get pods` — todos `Running`
2. Ingress / `minikube tunnel` — Swagger en cada API
3. Postman: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md)

---

## Limpieza

| Ruta | Comando |
|---|---|
| Minikube | `minikube delete` |
| AKS | `.\Remove-AzureShopDemo.ps1` o borrar RG |
| EKS | `.\Remove-AwsShopDemo.ps1` o `eksctl delete cluster` |
