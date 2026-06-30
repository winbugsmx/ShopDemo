# Requerimientos — Despliegue en Amazon EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Plataforma:** Amazon EKS  
**Versión:** 1.0

**Historias de usuario:** [HISTORIAS-USUARIO-DESPLIEGUE-EKS.md](./HISTORIAS-USUARIO-DESPLIEGUE-EKS.md)

---

## 1. Propósito

Desplegar ShopDemo en **EKS** con manifiestos **compartidos** en `k8s/` y **deployments** en `k8s/aws/` (imágenes **ECR**) e **Ingress NGINX**.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-EKS-01 | Crear cluster EKS (Consola + CLI/eksctl) |
| OBJ-EKS-02 | Publicar imágenes en ECR |
| OBJ-EKS-03 | Configurar `kubectl` contra EKS |
| OBJ-EKS-04 | Instalar Ingress NGINX y EBS CSI (PVC) |
| OBJ-EKS-05 | Aplicar manifiestos compartidos + **`k8s/aws/`** (imágenes ECR) |
| OBJ-EKS-06 | Validar flujo E2E |
| OBJ-EKS-07 | Documentar errores comunes |
| OBJ-EKS-08 | Aplicar **Secrets** K8s |
| OBJ-EKS-09 | Validar **Liveness/Readiness** HTTP |
| OBJ-EKS-10 | Ingress **Helm** + **HPA** Catalog |

---

## 3. Alcance

- Cluster EKS 1 node group (lab)
- ECR para imágenes
- Manifiestos `k8s/` compartidos con Minikube/AKS
- EBS CSI + Ingress Helm

## 4. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-EKS-01 | Nodos Ready en `kubectl get nodes` |
| CA-EKS-02 | Namespace `shopdemo` con todos los Pods Running |
| CA-EKS-03 | Ingress accesible vía DNS/IP del balanceador |
| CA-EKS-04 | Pasos realizados en Consola y CLI |
| CA-EKS-05 | Probes y HPA Catalog verificados |

---

## Referencias

- [TEORIA-KUBERNETES-OPERACIONES.md](../kubernetes/TEORIA-KUBERNETES-OPERACIONES.md)

- [TEORIA-EKS.md](./TEORIA-EKS.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](./IMPLEMENTACION-DESPLIEGUE-EKS.md)
