# Requerimientos — Despliegue en Azure AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Plataforma:** Azure Kubernetes Service (AKS)  
**Versión:** 1.0

---

## 1. Propósito

Desplegar ShopDemo en **AKS** reutilizando manifiestos `k8s/`, imágenes en **ACR** e **Ingress NGINX**, como extensión natural del laboratorio Minikube y complemento de Container Apps.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-AKS-01 | Crear cluster AKS (Portal + CLI) |
| OBJ-AKS-02 | Publicar 4 imágenes en ACR |
| OBJ-AKS-03 | Vincular AKS con ACR |
| OBJ-AKS-04 | Instalar Ingress NGINX |
| OBJ-AKS-05 | Aplicar manifiestos `k8s/` con imágenes ACR |
| OBJ-AKS-06 | Probar flujo E2E vía Ingress |
| OBJ-AKS-07 | Documentar errores comunes y mitigación |
| OBJ-AKS-08 | Aplicar **Secrets** K8s (`shopdemo-secrets`) |
| OBJ-AKS-09 | Validar **Liveness/Readiness** HTTP en pods |
| OBJ-AKS-10 | Instalar Ingress con **Helm** e instalar **HPA** Catalog |

---

## 3. Alcance

- Cluster AKS 1 node pool (lab)
- ACR Basic (reutilizar o crear)
- Mismos Deployments/StatefulSet/Ingress/HPA que Minikube
- Secrets con connection strings (Key Vault opcional — fuera de alcance básico)
- Ingress NGINX vía **Helm** (no addon)

## 4. Fuera de alcance

- Azure CNI avanzado / private cluster
- Workload Identity completo
- Azure Database for PostgreSQL (usamos StatefulSet en K8s)
- Azure Container Apps (guía separada)

---

## 5. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-AKS-01 | `kubectl get nodes` muestra nodos Ready |
| CA-AKS-02 | 4 Deployments + Postgres StatefulSet Running |
| CA-AKS-03 | Ingress con IP externa responde |
| CA-AKS-04 | Alumno completó pasos Portal y CLI |
| CA-AKS-05 | Probes HTTP y HPA Catalog operativos |

---

## Referencias

- [TEORIA-KUBERNETES-OPERACIONES.md](../kubernetes/TEORIA-KUBERNETES-OPERACIONES.md)

- [TEORIA-AKS.md](./TEORIA-AKS.md)
- [IMPLEMENTACION-DESPLIEGUE-AKS.md](./IMPLEMENTACION-DESPLIEGUE-AKS.md)
