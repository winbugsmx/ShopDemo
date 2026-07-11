# Cheat Sheet — Kubernetes CLI (`kubectl`)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Referencia rápida de comandos `kubectl` para desplegar y operar microservicios .NET en Kubernetes. Ejemplos orientados al despliegue de **ShopDemo** (Catalog y Orders).

---

## Configuración y contexto

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl version` | Versión de cliente y cluster | `kubectl version` |
| `kubectl config get-contexts` | Lista contextos disponibles | `kubectl config get-contexts` |
| `kubectl config use-context` | Cambia el contexto activo | `kubectl config use-context minikube` |
| `kubectl cluster-info` | Información del cluster | `kubectl cluster-info` |

---

## Namespaces

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl get namespaces` | Lista namespaces | `kubectl get ns` |
| `kubectl create namespace` | Crea un namespace | `kubectl create namespace shopdemo` |
| `kubectl config set-context` | Define namespace por defecto | `kubectl config set-context --current --namespace=shopdemo` |

**Organización recomendada para el curso:**

```bash
kubectl create namespace shopdemo
kubectl config set-context --current --namespace=shopdemo
```

---

## Recursos principales

| Recurso | Abreviatura | Uso en microservicios |
|---|---|---|
| `Pod` | `po` | Unidad mínima de ejecución |
| `Deployment` | `deploy` | Gestiona réplicas de un microservicio |
| `Service` | `svc` | Expone pods dentro/fuera del cluster |
| `ConfigMap` | `cm` | Configuración no sensible |
| `Secret` | — | Credenciales, connection strings |
| `Ingress` | `ing` | Enrutamiento HTTP externo |
| `PersistentVolumeClaim` | `pvc` | Almacenamiento persistente (BD) |

---

## Consultar recursos (GET)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl get pods` | Lista pods | `kubectl get pods` |
| `kubectl get deployments` | Lista deployments | `kubectl get deploy` |
| `kubectl get services` | Lista services | `kubectl get svc` |
| `kubectl get all` | Todos los recursos comunes | `kubectl get all` |
| `kubectl describe` | Detalle de un recurso | `kubectl describe pod catalog-api-xxx` |
| `kubectl get -o wide` | Más columnas (IP, nodo) | `kubectl get pods -o wide` |
| `kubectl get -o yaml` | Manifiesto YAML del recurso | `kubectl get deploy catalog-api -o yaml` |

**Vigilar pods en tiempo real:**

```bash
kubectl get pods -w
kubectl get pods -l app=catalog-api
```

---

## Aplicar y eliminar manifiestos (APPLY / DELETE)

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl apply -f` | Crea o actualiza recursos | `kubectl apply -f k8s/local/catalog/deployment.yaml` |
| `kubectl delete -f` | Elimina recursos de un manifiesto | `kubectl delete -f k8s/local/catalog/deployment.yaml` |
| `kubectl delete` | Elimina un recurso por nombre | `kubectl delete deploy catalog-api` |

**Desplegar el microservicio Catalog:**

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/local/catalog/deployment.yaml   # Minikube
# AKS: k8s/azure/...  |  EKS: k8s/aws/...
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/local/orders/deployment.yaml
```

---

## Deployments

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl create deployment` | Crea deployment rápido | `kubectl create deployment catalog-api --image=shopdemo-catalog:1.0` |
| `kubectl scale` | Cambia número de réplicas | `kubectl scale deploy catalog-api --replicas=3` |
| `kubectl rollout status` | Estado del despliegue | `kubectl rollout status deploy/catalog-api` |
| `kubectl rollout history` | Historial de revisiones | `kubectl rollout history deploy/catalog-api` |
| `kubectl rollout undo` | Revierte al despliegue anterior | `kubectl rollout undo deploy/catalog-api` |
| `kubectl set image` | Actualiza imagen del deployment | `kubectl set image deploy/catalog-api catalog-api=shopdemo-catalog:1.1` |

**Actualizar imagen tras nuevo build:**

```bash
docker build -t shopdemo-catalog:1.1 -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile Source
# Si usas registry:
docker push myregistry/shopdemo-catalog:1.1
kubectl set image deployment/catalog-api catalog-api=myregistry/shopdemo-catalog:1.1
kubectl rollout status deployment/catalog-api
```

---

## Logs y depuración

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl logs` | Logs de un pod | `kubectl logs catalog-api-abc123` |
| `kubectl logs -f` | Logs en tiempo real (follow) | `kubectl logs -f deploy/catalog-api` |
| `kubectl logs --previous` | Logs del contenedor anterior (crash) | `kubectl logs catalog-api-abc123 --previous` |
| `kubectl exec` | Ejecuta comando en un pod | `kubectl exec -it catalog-api-abc123 -- /bin/sh` |
| `kubectl port-forward` | Redirige puerto local al pod | `kubectl port-forward svc/catalog-api 8001:80` |
| `kubectl top pods` | Uso de CPU/RAM (requiere metrics-server) | `kubectl top pods` |

**Depurar Catalog.Api sin Ingress:**

```bash
# Acceder a la API desde localhost
kubectl port-forward svc/catalog-api 8001:80

# En otra terminal
curl http://localhost:8001/api/products
```

**Ver logs de un microservicio .NET:**

```bash
kubectl logs -f -l app=catalog-api --tail=100
```

---

## Services e Ingress

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl expose` | Crea un Service para un deployment | `kubectl expose deploy catalog-api --port=80 --target-port=8080` |
| `kubectl get endpoints` | Endpoints detrás de un Service | `kubectl get endpoints catalog-api` |
| `kubectl describe ingress` | Detalle de reglas de enrutamiento | `kubectl describe ingress shopdemo-ingress` |

**Tipos de Service:**

| Tipo | Uso |
|---|---|
| `ClusterIP` | Comunicación interna entre microservicios |
| `NodePort` | Expone en puerto del nodo (desarrollo) |
| `LoadBalancer` | IP externa (cloud providers) |

---

## ConfigMaps y Secrets

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl create configmap` | Crea ConfigMap | `kubectl create configmap catalog-config --from-literal=ASPNETCORE_ENVIRONMENT=Production` |
| `kubectl create secret` | Crea Secret | `kubectl create secret generic catalog-db-secret --from-literal=password=ShopDemo123` |
| `kubectl get configmap` | Lista ConfigMaps | `kubectl get cm` |
| `kubectl get secret` | Lista Secrets | `kubectl get secret` |
| `kubectl describe secret` | Detalle (valores en base64) | `kubectl describe secret catalog-db-secret` |

**Connection string como Secret (ShopDemo):**

```bash
kubectl create secret generic catalog-db-secret \
  --from-literal=ConnectionStrings__DefaultConnection="Host=postgres;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123"
```

**Referenciar en Deployment:**

```yaml
env:
  - name: ConnectionStrings__DefaultConnection
    valueFrom:
      secretKeyRef:
        name: catalog-db-secret
        key: ConnectionStrings__DefaultConnection
```

---

## Manifiestos de ejemplo (Catalog.Api)

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-api
  labels:
    app: catalog-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: catalog-api
  template:
    metadata:
      labels:
        app: catalog-api
    spec:
      containers:
        - name: catalog-api
          image: shopdemo-catalog:1.0
          ports:
            - containerPort: 8080
          env:
            - name: ASPNETCORE_ENVIRONMENT
              value: Production
            - name: ConnectionStrings__DefaultConnection
              valueFrom:
                secretKeyRef:
                  name: catalog-db-secret
                  key: ConnectionStrings__DefaultConnection
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
```

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: catalog-api
spec:
  selector:
    app: catalog-api
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

### ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shopdemo-ingress
spec:
  rules:
    - host: catalog.shopdemo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: catalog-api
                port:
                  number: 80
    - host: orders.shopdemo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: orders-api
                port:
                  number: 80
```

---

## Health checks en microservicios .NET

Agregar endpoint de salud en `Program.cs`:

```csharp
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
```

Kubernetes usa `readinessProbe` (¿puede recibir tráfico?) y `livenessProbe` (¿sigue vivo?) para reiniciar pods fallidos automáticamente.

---

## Comandos de diagnóstico

| Comando | Descripción | Ejemplo |
|---|---|---|
| `kubectl get events` | Eventos del cluster (errores, scheduling) | `kubectl get events --sort-by=.lastTimestamp` |
| `kubectl describe pod` | Razón de CrashLoopBackOff | `kubectl describe pod catalog-api-xxx` |
| `kubectl auth can-i` | Verifica permisos RBAC | `kubectl auth can-i create deployments` |
| `kubectl api-resources` | Lista recursos disponibles | `kubectl api-resources` |

**Pod en CrashLoopBackOff — checklist:**

```bash
kubectl describe pod <pod-name>       # Ver eventos y razón
kubectl logs <pod-name> --previous    # Logs del intento fallido
kubectl get secret catalog-db-secret  # Verificar que el secret existe
```

---

## Flujos comunes del curso

### Despliegue completo de ShopDemo

```bash
# 1. Namespace
kubectl create namespace shopdemo
kubectl config set-context --current --namespace=shopdemo

# 2. Secretos y configuración
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/configmaps/

# 3. Base de datos
kubectl apply -f k8s/postgres/

# 4. Microservicios (Minikube: k8s/local/; AKS: k8s/azure/; EKS: k8s/aws/)
kubectl apply -f k8s/catalog/service.yaml
kubectl apply -f k8s/local/catalog/deployment.yaml
kubectl apply -f k8s/orders/service.yaml
kubectl apply -f k8s/local/orders/deployment.yaml

# 5. Ingress
kubectl apply -f k8s/ingress/

# 6. Verificar
kubectl get all
kubectl rollout status deployment/catalog-api
```

### Escalar un microservicio

```bash
kubectl scale deployment catalog-api --replicas=3
kubectl get pods -l app=catalog-api
```

### Rollback tras despliegue fallido

```bash
kubectl rollout history deployment/catalog-api
kubectl rollout undo deployment/catalog-api
```

### Limpiar todo el namespace

```bash
kubectl delete namespace shopdemo
```

---

## Entornos locales para el curso

| Herramienta | Comando de inicio | Uso |
|---|---|---|
| **Minikube** | `minikube start` | Cluster local de un nodo |
| **Docker Desktop** | Habilitar Kubernetes en Settings | Cluster integrado |
| **Kind** | `kind create cluster` | Cluster en contenedores Docker |

**Cargar imagen local en Minikube (sin registry):**

```bash
eval $(minikube docker-env)
docker build -t shopdemo-catalog:1.0 -f Source/Catalog/ShopDemo.Catalog.Api/Dockerfile Source
kubectl apply -f k8s/local/catalog/deployment.yaml
```

---

## Atajos y aliases útiles

```bash
# Definir aliases (bash/zsh/PowerShell profile)
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kl='kubectl logs -f'
alias kd='kubectl describe'
```

**En PowerShell ($PROFILE):**

```powershell
function k { kubectl @args }
function kgp { kubectl get pods @args }
```

---

## Recursos

- [kubectl reference](https://kubernetes.io/Documentación del Proyecto/reference/kubectl/)
- [Kubernetes concepts](https://kubernetes.io/Documentación del Proyecto/concepts/)
- [Desplegar ASP.NET Core en Kubernetes](https://learn.microsoft.com/aspnet/core/host-and-deploy/docker/deploy-to-kubernetes)
