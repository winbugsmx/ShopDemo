# Requerimientos — Despliegue en Kubernetes (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Alcance:** Desarrollo y pruebas en Kubernetes (Minikube) + mismos manifiestos en AKS/EKS.  
**Versión:** 1.0

**Historias de usuario:** [HISTORIAS-USUARIO-KUBERNETES.md](./HISTORIAS-USUARIO-KUBERNETES.md)

---

## 1. Propósito

Justificar el despliegue de ShopDemo en **Kubernetes** como paso natural después de Docker Compose y antes/complemento de ACA/ECS: un solo conjunto de manifiestos YAML reutilizable en local y multicloud.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-K8-01 | Construir imágenes Docker de las 4 APIs |
| OBJ-K8-02 | Validar stack con **Docker Compose** en local |
| OBJ-K8-03 | Desplegar en **Minikube** con manifiestos `k8s/` |
| OBJ-K8-04 | Incluir **PostgreSQL** (StatefulSet) y **Azurite** en el cluster |
| OBJ-K8-05 | Exponer APIs vía **Ingress NGINX** |
| OBJ-K8-06 | Probar flujo E2E post-despliegue |
| OBJ-K8-07 | Reutilizar manifiestos en **AKS** y **EKS** con imágenes en ACR/ECR |
| OBJ-K8-08 | Dominar comandos básicos de **kubectl** (get, describe, logs, apply) |
| OBJ-K8-09 | Gestionar **Kubernetes Secrets** para PG y Event Hubs |
| OBJ-K8-10 | Configurar **Liveness y Readiness** HTTP (`/health`, `/alive`) |
| OBJ-K8-11 | Demostrar **HPA** en Catalog con metrics-server |
| OBJ-K8-12 | Ingress local vía **addon Minikube** (Helm solo en AKS/EKS) |

---

## 3. Alcance incluido

- Namespace `shopdemo`
- Deployments: Catalog, Orders, Inventory, Analytics
- StatefulSet: PostgreSQL (3 bases de datos)
- Deployment: Azurite (checkpoints)
- Services ClusterIP internos
- Ingress NGINX con host `shopdemo.local`
- Secrets para PG y Event Hubs (`k8s/secrets.example.yaml`)
- Probes HTTP en Deployments (`/health`, `/alive`)
- HPA de ejemplo en Catalog (`k8s/catalog/hpa.yaml`)
- metrics-server (addon Minikube)

## 4. Fuera de alcance

- Helm charts completos de ShopDemo
- HPA en las 4 APIs (solo Catalog como demo)
- Service mesh (Istio/Linkerd)
- CI/CD GitOps (ArgoCD) — solo referencia
- Native AOT en imágenes (documentado en TEORIA-DOCKER-KUBERNETES-AOT)

---

## 5. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-K8-01 | `kubectl get pods -n shopdemo` — todos Running |
| CA-K8-02 | Ingress responde en rutas `/catalog`, `/orders`, etc. |
| CA-K8-03 | Flujo crear producto → pedido → confirmar exitoso |
| CA-K8-04 | Mismos YAML aplicables en AKS/EKS cambiando imagen a ACR/ECR |
| CA-K8-05 | `kubectl describe pod` muestra probes `health`/`alive` en estado Success |
| CA-K8-06 | `kubectl get hpa -n shopdemo` muestra HPA de Catalog activo |

---

## Referencias

- [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md)

- [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md)
- [k8s/README.md](../../../k8s/README.md)
