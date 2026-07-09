# Anexo — Historias técnicas: Resiliencia (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-RES-01 — Configurar health probes en plataforma

| **HU** | HU-RES-02 |

**Como** alumno, **quiero** probes en ACA, ALB, o manifiestos K8s, **para** enrutar solo a instancias sanas.

### Criterios (CA-T)

- [ ] **CA-T-RES-02**

---

## HT-RES-02 — Simular fallo y verificar recuperación

| **HU** | HU-RES-01 |

**Como** alumno, **quiero** `kubectl delete pod` o reiniciar task ECS, **para** observar auto-recuperación.

### Criterios (CA-T)

- [ ] **CA-T-RES-01**

---

## HT-RES-03 — Configurar HPA o réplicas múltiples

| **HU** | HU-RES-03 |

**Como** alumno, **quiero** HPA Catalog o minReplicas ACA, **para** demostrar escalado.

### Criterios (CA-T)

- [ ] **CA-T-RES-03**

---

## HT-RES-04 — Documentar síncrono vs asíncrono

| **HU** | HU-RES-04 |

**Como** alumno, **quiero** escrito comparando fallo Inventory HTTP vs Event Hubs, **para** entregar a soporte.

---

## HT-RES-05 — Rolling update

| **HU** | HU-RES-05 |

**Como** alumno, **quiero** desplegar nueva revisión sin apagar todos los pods, **para** validar CA-T-RES-04.

### Referencias

- [azure/IMPLEMENTACION-RESILIENCIA-AZURE.md](./azure/IMPLEMENTACION-RESILIENCIA-AZURE.md)
- [aws/IMPLEMENTACION-RESILIENCIA-AWS.md](./aws/IMPLEMENTACION-RESILIENCIA-AWS.md)

### Criterios (CA-T)

- [ ] **CA-T-RES-04, CA-T-RES-05**

---

## Trazabilidad

| HU | HT |
|---|---|
| HU-RES-01 | HT-RES-02 |
| HU-RES-02 | HT-RES-01 |
| HU-RES-03 | HT-RES-03 |
| HU-RES-04 | HT-RES-04 |
| HU-RES-05 | HT-RES-05 |
