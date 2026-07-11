# Anexo — Pedagogía: Despliegue EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Crear cluster **EKS** con eksctl o consola.
2. Configurar **EBS CSI** y **Ingress Helm**.
3. Desplegar manifiestos `k8s/aws/` con imágenes **ECR**.
4. Validar **E2E** y recuperación de pods.
5. Automatizar con **deploy-eks.yml**.

---

## 2. Tiempo estimado

| Actividad | Duración |
|---|---|
| Cluster EKS | 1.5–2 h |
| CSI + Ingress + manifiestos | 1.5–2 h |
| E2E | 1 h |
| **Total** | **4–5 h** |

---

## 3. Entregables

| # | Entregable |
|---|---|
| 1 | Cluster EKS con pods Running |
| 2 | Captura Ingress + flujo E2E |
| 3 | Evidencia recuperación pod |
| 4 | Consola + CLI documentados |

---

## 4. Posición

Etapa 11 — cierre multicloud Kubernetes. Paralelo a AKS en Azure.

---

## 5. Referencias

- [IMPLEMENTACION-DESPLIEGUE-EKS.md](./IMPLEMENTACION-DESPLIEGUE-EKS.md)
