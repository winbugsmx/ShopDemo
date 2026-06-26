# Historias de Usuario — Resiliencia (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-RESILIENCIA.md](./REQUERIMIENTOS-RESILIENCIA.md) |

---

## HU-RES-01 — Health checks en todas las plataformas

| **Objetivo** | OBJ-RES-01 |

**Como** orquestador (ACA/ECS/K8s), **quiero** probes en `/health`, **para** no enviar tráfico a instancias caídas.

**Modelo:** Endpoints existentes en código; config en manifiestos/ACA/ALB.

**Criterios (CA-RES-02):** Probes configurados en 4 servicios × plataforma elegida.

---

## HU-RES-02 — Recuperación tras fallo de instancia

| **Objetivo** | OBJ-RES-04 |

**Como** alumno, **quiero** eliminar un pod o reiniciar task ECS, **para** ver auto-recuperación.

**Criterios (CA-RES-01):** Servicio vuelve a Ready/Running sin intervención manual prolongada.

---

## HU-RES-03 — Redundancia y escalado

| **Objetivos** | OBJ-RES-02, OBJ-RES-05 |

**Reglas:** minReplicas ≥ 1; HPA Catalog en K8s; desired count ≥ 1 en ECS.

**Criterios (CA-RES-04):** Escalado manual o HPA demostrado.

---

## HU-RES-04 — Comunicación síncrona vs asíncrona

| **Objetivo** | OBJ-RES-03 |

**Como** alumno, **quiero** explicar fallo Orders→Inventory vs Event Hubs, **para** entender patrones de resiliencia.

**Criterios (CA-RES-03):** Respuesta escrita o oral documentada en entrega.

---

## HU-RES-05 — Rolling updates sin downtime total

| **Objetivo** | OBJ-RES-06 (implícito en alcance) |

**Criterios (CA-RES-05):** Guías Azure y AWS de resiliencia completadas.
