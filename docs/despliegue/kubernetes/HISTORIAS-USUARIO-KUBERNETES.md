# Historias de Usuario — Kubernetes local (Minikube)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-KUBERNETES.md](./REQUERIMIENTOS-KUBERNETES.md) |

---

## HU-K8-01 — Validar imágenes con Docker Compose

| **Objetivo** | OBJ-K8-02 |

**Como** alumno, **quiero** probar Docker por servicio antes de K8s, **para** aislar errores de Dockerfile.

**Modelo:** **N/A** — contenedores locales.

**Criterios:** Al menos un servicio responde en Swagger local.

---

## HU-K8-02 — Desplegar stack en Minikube

| **Objetivos** | OBJ-K8-03, OBJ-K8-04, OBJ-K8-05 |

**Como** alumno, **quiero** aplicar manifiestos compartidos + **`k8s/local/`**, **para** ejecutar 5 APIs + Postgres + Azurite + Ingress.

**Modelo:** Manifiestos YAML; **Secret** `k8s/secrets.yaml` (no commitear).

**Reglas:** Namespace `shopdemo`; orden postgres → azurite → APIs → ingress.

**Criterios (CA-K8-01, CA-K8-02):** Todos pods Running; Ingress responde rutas.

---

## HU-K8-03 — Secrets y Event Hubs

| **Objetivo** | OBJ-K8-09 |

**Modelo:** `secrets.example.yaml` → `secrets.yaml` con connection strings.

**Criterios:** Pods arrancan sin CrashLoop por secretos faltantes.

---

## HU-K8-04 — Health probes

| **Objetivo** | OBJ-K8-10 |

**Reglas:** Liveness/readiness en `/health` y `/alive`.

**Criterios (CA-K8-05):** `kubectl describe pod` muestra probes Success.

---

## HU-K8-05 — HPA en Catalog

| **Objetivo** | OBJ-K8-11 |

**Modelo:** `k8s/catalog/hpa.yaml`; metrics-server habilitado.

**Criterios (CA-K8-06):** `kubectl get hpa` muestra HPA activo.

---

## HU-K8-06 — Flujo E2E y reutilización cloud

| **Objetivos** | OBJ-K8-06, OBJ-K8-07 |

**Criterios (CA-K8-03, CA-K8-04):** Flujo producto→pedido→confirmar; carpeta de deployments según entorno (`local/`, `azure/`, `aws/`).

---

## HU-K8-07 — Dominio kubectl básico

| **Objetivo** | OBJ-K8-08 |

**Criterios:** Alumno ejecuta get, describe, logs, apply sin guía constante.
