# Historias de Usuario — Despliegue EKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-EKS.md](./REQUERIMIENTOS-DESPLIEGUE-EKS.md) |

---

## HU-EKS-01 — Crear cluster EKS

| **Objetivo** | OBJ-EKS-01 |

**Como** alumno, **quiero** cluster EKS (eksctl o consola), **para** orquestar manifiestos ShopDemo.

**Criterios (CA-EKS-01):** Nodos Ready.

---

## HU-EKS-02 — Imágenes ECR y kubeconfig

| **Objetivos** | OBJ-EKS-02, OBJ-EKS-03 |

**Criterios:** Imágenes en ECR; `kubectl get nodes` funciona.

---

## HU-EKS-03 — EBS CSI e Ingress Helm

| **Objetivo** | OBJ-EKS-04, OBJ-EKS-10 |

**Reglas:** PVC para Postgres; Ingress NGINX vía Helm.

**Criterios (CA-EKS-03):** Ingress accesible.

---

## HU-EKS-04 — Desplegar namespace shopdemo

| **Objetivos** | OBJ-EKS-05, OBJ-EKS-08, OBJ-EKS-09 |

**Criterios (CA-EKS-02, CA-EKS-05):** Todos pods Running; probes y HPA Catalog OK.

---

## HU-EKS-05 — Validación E2E y dual Consola/CLI

| **Objetivos** | OBJ-EKS-06, OBJ-EKS-07 |

**Criterios (CA-EKS-04):** Pasos en Consola y CLI documentados.
