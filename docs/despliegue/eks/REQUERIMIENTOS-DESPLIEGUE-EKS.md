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

---

## 1. Propósito

Desplegar ShopDemo en **EKS** con los mismos manifiestos `k8s/` usados en Minikube y AKS, imágenes en **ECR** e **Ingress NGINX**.

---

## 2. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-EKS-01 | Crear cluster EKS (Consola + CLI/eksctl) |
| OBJ-EKS-02 | Publicar imágenes en ECR |
| OBJ-EKS-03 | Configurar `kubectl` contra EKS |
| OBJ-EKS-04 | Instalar Ingress NGINX y EBS CSI (PVC) |
| OBJ-EKS-05 | Aplicar manifiestos ShopDemo |
| OBJ-EKS-06 | Validar flujo E2E |
| OBJ-EKS-07 | Documentar errores comunes |

---

## 3. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-EKS-01 | Nodos Ready en `kubectl get nodes` |
| CA-EKS-02 | Namespace `shopdemo` con todos los Pods Running |
| CA-EKS-03 | Ingress accesible vía DNS/IP del balanceador |
| CA-EKS-04 | Pasos realizados en Consola y CLI |

---

## Referencias

- [TEORIA-EKS.md](./TEORIA-EKS.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](./IMPLEMENTACION-DESPLIEGUE-EKS.md)
