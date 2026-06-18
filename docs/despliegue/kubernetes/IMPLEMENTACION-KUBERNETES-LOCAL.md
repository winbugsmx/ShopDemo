# Implementación — Kubernetes local (Minikube + ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Entorno:** Minikube · **Manifiestos:** `k8s/`  
**Teoría:** [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md)  
Cada paso incluye explicación breve. Para AKS/EKS ver guías específicas (mismos YAML).

---

## Índice

1. [Prerequisitos](#1-prerequisitos)
2. [Paso 1 — Docker Compose (validación previa)](#2-paso-1--docker-compose-validación-previa)
3. [Paso 2 — Instalar y arrancar Minikube](#3-paso-2--instalar-y-arrancar-minikube)
4. [Paso 3 — Habilitar Ingress NGINX](#4-paso-3--habilitar-ingress-nginx)
5. [Paso 4 — Construir imágenes en el daemon de Minikube](#5-paso-4--construir-imágenes-en-el-daemon-de-minikube)
6. [Paso 5 — Configurar Secrets](#6-paso-5--configurar-secrets)
7. [Paso 6 — Desplegar infraestructura (Postgres + Azurite)](#7-paso-6--desplegar-infraestructura-postgres--azurite)
8. [Paso 7 — Desplegar las 4 APIs](#8-paso-7--desplegar-las-4-apis)
9. [Paso 8 — Desplegar Ingress](#9-paso-8--desplegar-ingress)
10. [Paso 9 — Testeo del despliegue](#10-paso-9--testeo-del-despliegue)
11. [Solución de problemas](#11-solución-de-problemas)
12. [Anexo A — Uso de kubectl](#12-anexo-a--uso-de-kubectl)
13. [Anexo B — Kubernetes Secrets](#13-anexo-b--kubernetes-secrets)
14. [Anexo C — Liveness y Readiness](#14-anexo-c--liveness-y-readiness)
15. [Anexo D — Autoscaling (HPA)](#15-anexo-d--autoscaling-hpa)
16. [Anexo E — Ingress (addon Minikube)](#16-anexo-e--ingress-addon-minikube)

---

## 1. Prerequisitos

- Docker Desktop
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) instalado
- `kubectl` instalado
- ShopDemo clonado
- Connection string de **Azure Event Hubs** (opcional pero recomendado)

```bash
minikube version
kubectl version --client
```

---

## 2. Paso 1 — Docker Compose (validación previa)

**Objetivo:** Confirmar que las imágenes Docker funcionan antes de Kubernetes.

```bash
cd Catalog/ShopDemo.Catalog.Api
docker compose up --build -d
curl http://localhost:8001/swagger/index.html
docker compose down
```

Repetir mentalmente para Orders/Inventory o confiar en el build del paso 5.  
**Por qué:** Aísla errores de Dockerfile vs errores de manifiestos K8s.

---

## 3. Paso 2 — Instalar y arrancar Minikube

**Objetivo:** Cluster Kubernetes local de un nodo.

### CLI (recomendado)

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
kubectl get nodes
```

### Verificación

```bash
minikube status
```

> Ajusta `--memory` si tu máquina tiene poca RAM (mínimo 6 GB para 4 APIs + Postgres).

---

## 4. Paso 3 — Habilitar Ingress NGINX

**Objetivo:** Controlador para exponer HTTP con un solo punto de entrada.

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

Espera a que el pod `ingress-nginx-controller` esté `Running`.

---

## 5. Paso 4 — Construir imágenes en el daemon de Minikube

**Objetivo:** Imágenes locales sin registry (`imagePullPolicy: IfNotPresent`).

```bash
cd I:\Curso\ShopDemo
minikube docker-env | Invoke-Expression   # PowerShell
# eval $(minikube docker-env)             # Bash

docker build -f Catalog/ShopDemo.Catalog.Api/Dockerfile -t shopdemo-catalog:latest .
docker build -f Orders/ShopDemo.Orders.Api/Dockerfile -t shopdemo-orders:latest .
docker build -f Inventory/ShopDemo.Inventory.Api/Dockerfile -t shopdemo-inventory:latest .
docker build -f Aspire/ShopDemo.Analytics.Api/Dockerfile -t shopdemo-analytics:latest .

docker images | findstr shopdemo
```

**Explicación:** `minikube docker-env` apunta el CLI de Docker al daemon interno de Minikube.

---

## 6. Paso 5 — Configurar Secrets

**Objetivo:** Credenciales fuera de los Deployments.

```bash
copy k8s\secrets.example.yaml k8s\secrets.yaml
# Editar EVENT_HUBS_CONNECTION_STRING en secrets.yaml

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
```

> **No commitear** `secrets.yaml`. Está en `.gitignore` si lo agregas localmente.

---

## 7. Paso 6 — Desplegar infraestructura (Postgres + Azurite)

**Objetivo:** Base de datos y emulador de blobs antes de las APIs.

```bash
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/

kubectl wait --for=condition=ready pod -l app=shopdemo-postgres -n shopdemo --timeout=120s
kubectl get pods -n shopdemo
```

**Explicación:** PostgreSQL usa **StatefulSet** con PVC; Azurite es **Deployment** simple.

---

## 8. Paso 7 — Desplegar las 4 APIs

**Objetivo:** Microservicios con variables desde Secrets y DNS interno.

```bash
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/inventory/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/analytics/
kubectl apply -f k8s/catalog/hpa.yaml

kubectl get pods -n shopdemo -w
```

**Orders → Inventory:** `InventoryApi__BaseUrl=http://shopdemo-inventory:8080` (Service DNS).

---

## 9. Paso 8 — Desplegar Ingress

**Objetivo:** Rutas HTTP bajo `shopdemo.local`.

```bash
kubectl apply -f k8s/ingress/

# Obtener IP del Ingress
kubectl get ingress -n shopdemo
```

### Configurar hosts local

```bash
minikube ip
# Agregar a C:\Windows\System32\drivers\etc\hosts:
# <MINIKUBE_IP>  shopdemo.local
```

O usar túnel:

```bash
minikube tunnel
```

---

## 10. Paso 9 — Testeo del despliegue

| # | Prueba | Comando / URL |
|---|---|---|
| 1 | Pods Running | `kubectl get pods -n shopdemo` |
| 2 | Probes OK | `kubectl describe pod -n shopdemo -l app=shopdemo-catalog` → Readiness/Liveness |
| 3 | Health HTTP | `kubectl port-forward -n shopdemo svc/shopdemo-catalog 8001:8080` → `curl http://localhost:8001/health` |
| 4 | Logs Catalog | `kubectl logs -n shopdemo -l app=shopdemo-catalog` |
| 5 | Swagger Catalog | `http://shopdemo.local/catalog/swagger` o port-forward |
| 6 | HPA | `kubectl get hpa -n shopdemo` |
| 7 | Crear producto | Postman / [GUIA-ENDPOINTS.md](../../GUIA-ENDPOINTS.md) |
| 8 | Analytics eventos | `http://shopdemo.local/analytics/api/analytics/events` |
| 9 | Flujo E2E | Crear producto → stock → pedido → confirmar |

### Comandos de diagnóstico

```bash
kubectl describe pod -n shopdemo -l app=shopdemo-orders
kubectl get events -n shopdemo --sort-by=.metadata.creationTimestamp
```

---

## 11. Solución de problemas

| Síntoma | Causa | Acción |
|---|---|---|
| `ImagePullBackOff` | Imagen no en daemon Minikube | Repetir paso 4 con `minikube docker-env` |
| Postgres `Pending` | PVC / storage class | `minikube addons enable default-storageclass` |
| Ingress 404 | Host no configurado | Verificar `/etc/hosts` o `minikube tunnel` |
| Orders falla al confirmar | Inventory URL | `kubectl get svc shopdemo-inventory -n shopdemo` |
| Sin eventos Analytics | Event Hubs secret | Revisar `EVENT_HUBS_CONNECTION_STRING` |
| Probes failing | Imagen antigua sin `/health` | Rebuild imágenes (paso 4) y `kubectl rollout restart` |
| HPA `<unknown>` | metrics-server ausente | `minikube addons enable metrics-server` |

### Limpiar

```bash
kubectl delete namespace shopdemo
minikube stop
```

---

## 12. Anexo A — Uso de kubectl

**Objetivo:** Familiarizarse con la CLI antes y después del despliegue.

| Paso | Comando | Qué observar |
|---|---|---|
| 1 | `kubectl config current-context` | Debe ser `minikube` |
| 2 | `kubectl get all -n shopdemo` | Pods, Services, Deployments |
| 3 | `kubectl describe deployment shopdemo-catalog -n shopdemo` | Réplicas, imagen, eventos |
| 4 | `kubectl logs -f -n shopdemo -l app=shopdemo-orders --tail=20` | Logs en tiempo real |
| 5 | `kubectl exec -it -n shopdemo <pod-postgres> -- psql -U ShopDemo -d ShopDemoCatalog -c '\dt'` | Acceso opcional a BD |

**Actualizar tras cambio de manifiesto:**

```bash
kubectl apply -f k8s/catalog/deployment.yaml
kubectl rollout status deployment/shopdemo-catalog -n shopdemo
```

Cheat sheet: [kubernetes-cli.md](../../cheat-sheets/kubernetes-cli.md)

---

## 13. Anexo B — Kubernetes Secrets

**Objetivo:** Centralizar credenciales en un Secret del namespace.

| Paso | Acción |
|---|---|
| 1 | `copy k8s\secrets.example.yaml k8s\secrets.yaml` |
| 2 | Editar `EVENT_HUBS_CONNECTION_STRING` con tu connection string Azure |
| 3 | `kubectl apply -f k8s/secrets.yaml` |
| 4 | Verificar: `kubectl get secret shopdemo-secrets -n shopdemo` |

**Claves del Secret:**

| Key | Consumidor |
|---|---|
| `PG_CATALOG_CONN` | Catalog Deployment |
| `PG_ORDERS_CONN` | Orders Deployment |
| `PG_INVENTORY_CONN` | Inventory Deployment |
| `EVENT_HUBS_CONNECTION_STRING` | Las 4 APIs |
| `AZURITE_CHECKPOINT_CONN` | Inventory + Analytics |

**Rotar un secreto:** editar `secrets.yaml` → `kubectl apply -f k8s/secrets.yaml` → `kubectl rollout restart deployment -n shopdemo`.

---

## 14. Anexo C — Liveness y Readiness

**Objetivo:** Kubernetes reinicia pods caídos y no envía tráfico hasta que la API responde.

### Código (ya en el repo)

Las 4 APIs exponen:

- `GET /health` → readiness
- `GET /alive` → liveness

### Manifiestos

Ver `k8s/catalog/deployment.yaml` (mismo patrón en orders, inventory, analytics).

### Verificación

```bash
kubectl describe pod -n shopdemo -l app=shopdemo-catalog | findstr -i "readiness liveness"
kubectl port-forward -n shopdemo svc/shopdemo-catalog 8001:8080
curl http://localhost:8001/health
curl http://localhost:8001/alive
```

| Probe | Si falla |
|---|---|
| Readiness | Pod no recibe tráfico del Service |
| Liveness | Kubernetes reinicia el contenedor |

---

## 15. Anexo D — Autoscaling (HPA)

**Objetivo:** Escalar Catalog de 1 a 3 réplicas cuando la CPU supera el 70 %.

| Paso | Comando |
|---|---|
| 1 | Habilitar métricas: `minikube addons enable metrics-server` |
| 2 | Esperar ~1 min; verificar: `kubectl get apiservices \| findstr metrics` |
| 3 | Aplicar HPA: `kubectl apply -f k8s/catalog/hpa.yaml` |
| 4 | Estado: `kubectl get hpa shopdemo-catalog-hpa -n shopdemo` |

**Demostración rápida (opcional):**

```bash
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -n shopdemo -- /bin/sh -c "while true; do wget -q -O- http://shopdemo-catalog:8080/swagger/index.html; done"
# En otra terminal: kubectl get hpa -n shopdemo -w
```

Detener el pod de carga con `Ctrl+C`. El HPA reducirá réplicas tras unos minutos.

> Solo **Catalog** tiene HPA en este curso; las demás APIs mantienen 1 réplica.

---

## 16. Anexo E — Ingress (addon Minikube)

**Objetivo:** Un punto de entrada HTTP para las 4 APIs.

En **Minikube** se usa el **addon** (no Helm):

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
kubectl apply -f k8s/ingress/
```

| Ruta Ingress | Service destino |
|---|---|
| `/catalog` | shopdemo-catalog |
| `/orders` | shopdemo-orders |
| `/inventory` | shopdemo-inventory |
| `/analytics` | shopdemo-analytics |

En **AKS y EKS** el mismo `ingress.yaml` funciona tras instalar el controlador con **Helm** (ver guías de nube).

---

## Siguiente paso

- **Azure AKS:** [IMPLEMENTACION-DESPLIEGUE-AKS.md](../aks/IMPLEMENTACION-DESPLIEGUE-AKS.md)
- **Amazon EKS:** [IMPLEMENTACION-DESPLIEGUE-EKS.md](../eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)
