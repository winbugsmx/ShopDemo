# Implementación — Despliegue en Azure AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Prerequisito:** [IMPLEMENTACION-KUBERNETES-LOCAL.md](../kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) (Minikube)  
Cada paso: **Portal Azure** + **Azure CLI**.

---

## Índice

1. [Variables del laboratorio](#1-variables-del-laboratorio)
2. [Paso 1 — Resource Group y ACR](#2-paso-1--resource-group-y-acr)
3. [Paso 2 — Crear cluster AKS](#3-paso-2--crear-cluster-aks)
4. [Paso 3 — Conectar kubectl](#4-paso-3--conectar-kubectl)
5. [Paso 4 — Build y push a ACR](#5-paso-4--build-y-push-a-acr)
6. [Paso 5 — Instalar Ingress NGINX](#6-paso-5--instalar-ingress-nginx)
7. [Paso 6 — Ajustar manifiestos para ACR](#7-paso-6--ajustar-manifiestos-para-acr)
8. [Paso 7 — Desplegar ShopDemo](#8-paso-7--desplegar-shopdemo)
9. [Paso 8 — Testeo](#9-paso-8--testeo)
10. [Paso 9 — Limpieza](#10-paso-9--limpieza)

---

## 1. Variables del laboratorio

```bash
$RG = "rg-shopdemo-aks"
$LOCATION = "eastus"
$ACR_NAME = "acrshopdemolab"
$AKS_NAME = "aks-shopdemo"
```

---

## 2. Paso 1 — Resource Group y ACR

**Objetivo:** Registro de imágenes (reutilizar ACR de ACA si existe).

### Portal Azure

1. **Resource groups** → `rg-shopdemo-aks` (o usar existente)
2. **Container Registry** → crear o seleccionar `acrshopdemolab`

### CLI

```bash
az group create --name $RG --location $LOCATION
az acr create --resource-group $RG --name $ACR_NAME --sku Basic
```

---

## 3. Paso 2 — Crear cluster AKS

**Objetivo:** Cluster con 1–2 nodos para el lab.

### Portal Azure

1. **Kubernetes services** → **Create**
2. **Basics:** name `aks-shopdemo`, region, RG
3. **Node pools:** 1 pool, tamaño `Standard_B2s`, count `1`
4. **Integrations:** habilitar **Container Registry** → seleccionar ACR
5. **Networking:** defaults (Azure CNI o overlay según wizard)
6. **Create** (10–15 min)

### CLI

```bash
az aks create \
  --resource-group $RG \
  --name $AKS_NAME \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys

az aks show --resource-group $RG --name $AKS_NAME --query provisioningState
```

**Explicación:** `--attach-acr` evita `ImagePullBackOff` por permisos.

---

## 4. Paso 3 — Conectar kubectl

### Portal

1. AKS cluster → **Connect** → copiar comandos `az aks get-credentials`

### CLI

```bash
az aks get-credentials --resource-group $RG --name $AKS_NAME
kubectl get nodes
```

---

## 5. Paso 4 — Build y push a ACR

**Objetivo:** Imágenes en la nube (no locales).

```bash
cd I:\Curso\ShopDemo
az acr login --name $ACR_NAME
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t $ACR_LOGIN/shopdemo-catalog:v1 .
docker push $ACR_LOGIN/shopdemo-catalog:v1
# Repetir orders, inventory, analytics
```

---

## 6. Paso 5 — Instalar Ingress NGINX

### Portal (Marketplace)

1. Buscar **NGINX Ingress Controller** o usar Helm desde Cloud Shell

### CLI (Helm)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
kubectl get svc -n ingress-nginx
```

---

## 7. Paso 6 — Ajustar manifiestos para ACR

**Objetivo:** Cambiar `image: shopdemo-catalog:latest` por ACR.

Opción rápida — patch en línea al aplicar:

```bash
$ACR_LOGIN = az acr show --name $ACR_NAME --query loginServer -o tsv

# Ejemplo Catalog
(Get-Content k8s/catalog/deployment.yaml) `
  -replace 'shopdemo-catalog:latest', "$ACR_LOGIN/shopdemo-catalog:v1" |
  Set-Content k8s/catalog/deployment-aks.yaml
```

O editar `deployment.yaml` con la ruta completa ACR y `imagePullPolicy: Always`.

---

## 8. Paso 7 — Desplegar ShopDemo

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
kubectl wait --for=condition=ready pod -l app=shopdemo-postgres -n shopdemo --timeout=300s
kubectl apply -f k8s/catalog/deployment-aks.yaml  # o deployment.yaml editado
kubectl apply -f k8s/catalog/service.yaml
# inventory, orders, analytics...
kubectl apply -f k8s/ingress/
```

---

## 9. Paso 8 — Testeo

```bash
$INGRESS_IP = kubectl get ingress shopdemo-ingress -n shopdemo -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo "http://$INGRESS_IP/catalog/swagger"

kubectl get pods -n shopdemo
kubectl logs -n shopdemo -l app=shopdemo-catalog --tail=50
```

Flujo E2E: [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) (ajustar URLs al Ingress).

| Prueba | Esperado |
|---|---|
| Pods | Todos `Running` |
| Crear producto | `201` Catalog |
| Analytics | Eventos en `/analytics/api/analytics/events` |
| Confirmar pedido | `200` Orders |

---

## 10. Paso 9 — Limpieza

### Portal

Resource Group → **Delete resource group**

### CLI

```bash
az group delete --name $RG --yes --no-wait
```

---

## Errores comunes (AKS)

Ver [TEORIA-AKS.md](./TEORIA-AKS.md) §4.

---

## Referencias

- [TEORIA-AKS.md](./TEORIA-AKS.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) (ACR compartido)
