# Anexo — Historias técnicas: Despliegue EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-EKS-01 — Crear cluster EKS

| **HU** | HU-EKS-04 |

**Como** alumno, **quiero** cluster EKS (eksctl o consola), **para** orquestar ShopDemo.

### Criterios (CA-T)

- [ ] **CA-T-EKS-01**

---

## HT-EKS-02 — Imágenes ECR y kubeconfig

| **HU** | HU-EKS-01 |

**Como** alumno, **quiero** push ECR y `aws eks update-kubeconfig`, **para** kubectl operativo.

### Criterios (CA-T)

- [ ] **CA-T-EKS-04**

---

## HT-EKS-03 — EBS CSI e Ingress Helm

| **HU** | HU-EKS-01 |

**Como** alumno, **quiero** EBS CSI + Ingress NGINX Helm, **para** PVC Postgres y entrada HTTP.

### Criterios (CA-T)

- [ ] **CA-T-EKS-03**

---

## HT-EKS-04 — Desplegar namespace shopdemo

| **HU** | HU-EKS-01, HU-EKS-02 |

**Como** alumno, **quiero** apply `k8s/` + `k8s/aws/` con secrets, **para** stack completo.

### Criterios (CA-T)

- [ ] **CA-T-EKS-02, CA-T-EKS-05**

---

## HT-EKS-05 — E2E y recuperación

| **HU** | HU-EKS-02, HU-EKS-03 |

**Como** alumno, **quiero** flujo E2E y prueba delete pod, **para** validar resiliencia básica.

---

## HT-EKS-06 — CI/CD dual Consola/CLI

| **HU** | HU-EKS-04 |

### Criterios (CA-T)

- [ ] **CA-T-EKS-06**

---

## Trazabilidad

| HU | HT |
|---|---|
| HU-EKS-01 | HT-EKS-02, HT-EKS-03, HT-EKS-04 |
| HU-EKS-02 | HT-EKS-04, HT-EKS-05 |
| HU-EKS-03 | HT-EKS-05 |
| HU-EKS-04 | HT-EKS-01, HT-EKS-06 |
