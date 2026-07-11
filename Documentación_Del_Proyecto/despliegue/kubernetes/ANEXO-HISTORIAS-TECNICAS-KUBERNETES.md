# Anexo — Historias técnicas: Kubernetes local (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-K8-01 — Validar imágenes con Docker Compose

**Como** alumno, **quiero** probar Docker por servicio antes de K8s, **para** aislar errores de Dockerfile.

### Criterios (CA-T)

- [ ] Al menos un servicio responde en Swagger local.

---

## HT-K8-02 — Configurar Minikube

**Como** alumno, **quiero** Minikube con addons ingress y metrics-server, **para** Ingress y HPA.

---

## HT-K8-03 — Aplicar manifiestos compartidos + local

| **Historia negocio** | HU-K8-01, HU-K8-02 |

**Como** alumno, **quiero** `kubectl apply` en orden correcto, **para** levantar 5 APIs + Postgres + Azurite.

### Tareas

1. Namespace, postgres, azurite
2. `secrets.yaml` desde `secrets.example.yaml`
3. Deployments `k8s/local/`
4. Ingress

### Criterios (CA-T)

- [ ] **CA-T-K8-01, CA-T-K8-02**

---

## HT-K8-04 — Configurar secrets y Event Hubs

| **Historia negocio** | HU-K8-02 |

### Criterios (CA-T)

- [ ] **CA-T-K8-03:** Sin CrashLoop por secretos.

---

## HT-K8-05 — Health probes y HPA

| **Historias negocio** | HU-K8-03, HU-K8-04 |

### Criterios (CA-T)

- [ ] **CA-T-K8-04, CA-T-K8-05**

---

## HT-K8-06 — Dominio kubectl y E2E

**Como** alumno, **quiero** dominar get, describe, logs, apply, **para** operar sin guía constante.

### Criterios (CA-T)

- [ ] Flujo E2E documentado; **CA-T-K8-06** carpetas cloud correctas.

---

## Trazabilidad

| HU negocio | HT técnica |
|---|---|
| HU-K8-01 | HT-K8-02, HT-K8-03 |
| HU-K8-02 | HT-K8-03, HT-K8-04 |
| HU-K8-03 | HT-K8-05 |
| HU-K8-04 | HT-K8-05, HT-K8-06 |
