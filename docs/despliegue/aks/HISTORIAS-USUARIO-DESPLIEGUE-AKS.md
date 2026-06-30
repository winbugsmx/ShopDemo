# Historias de Usuario — Despliegue AKS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-AKS.md](./REQUERIMIENTOS-DESPLIEGUE-AKS.md) |

---

## HU-AKS-01 — Crear cluster y vincular ACR

| **Objetivos** | OBJ-AKS-01, OBJ-AKS-02, OBJ-AKS-03 |

**Como** alumno, **quiero** cluster AKS + imágenes en ACR, **para** pull autenticado desde nodos.

**Modelo:** **N/A** infra; manifiestos con URI ACR.

**Criterios (CA-AKS-01):** Nodos Ready.

---

## HU-AKS-02 — Ingress NGINX con Helm

| **Objetivo** | OBJ-AKS-04, OBJ-AKS-10 |

**Criterios (CA-AKS-03):** Ingress con IP externa responde.

---

## HU-AKS-03 — Aplicar manifiestos ShopDemo

| **Objetivos** | OBJ-AKS-05, OBJ-AKS-08 |

**Como** alumno, **quiero** aplicar manifiestos compartidos + **`k8s/azure/`** con secrets y probes, **para** mismo stack que Minikube en nube.

**Criterios (CA-AKS-02, CA-AKS-05):** 4 Deployments + Postgres Running; probes OK.

---

## HU-AKS-04 — Flujo E2E y documentación dual

| **Objetivos** | OBJ-AKS-06, OBJ-AKS-07 |

**Criterios (CA-AKS-04):** Portal + CLI completados; flujo E2E vía Ingress.
