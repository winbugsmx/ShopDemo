# Anexo — Historias técnicas: Observabilidad (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-OBS-01 — Habilitar diagnósticos ACA → Log Analytics

| **HU** | HU-OBS-01 |

**Como** alumno, **quiero** Container Apps Environment vinculado a Log Analytics, **para** centralizar logs ACA.

### Criterios (CA-T)

- [ ] **CA-T-OBS-01** (rama Azure)

---

## HT-OBS-02 — Configurar CloudWatch en ECS/EKS

| **HU** | HU-OBS-01 |

**Como** alumno, **quiero** log groups por servicio ECS/EKS, **para** logs agregados AWS.

---

## HT-OBS-03 — Ejecutar consulta KQL / Logs Insights

| **HU** | HU-OBS-02, HU-OBS-03 |

**Como** alumno, **quiero** filtrar por servicio y traceId, **para** correlacionar errores.

### Criterios (CA-T)

- [ ] **CA-T-OBS-02, CA-T-OBS-03**

---

## HT-OBS-04 — Crear alerta por umbral

| **HU** | HU-OBS-04 |

**Como** alumno, **quiero** regla de alerta 5xx o CPU, **para** demostrar operación proactiva.

### Criterios (CA-T)

- [ ] **CA-T-OBS-04**

---

## HT-OBS-05 — Simular y documentar investigación E2E

| **HU** | HU-OBS-05 |

**Como** alumno, **quiero** reproducir fallo controlado (ej. URL Inventory incorrecta) y documentar pasos, **para** entregar guía de soporte.

### Criterios (CA-T)

- [ ] **CA-T-OBS-05**

---

## Trazabilidad

| HU | HT |
|---|---|
| HU-OBS-01 | HT-OBS-01, HT-OBS-02 |
| HU-OBS-02 | HT-OBS-03 |
| HU-OBS-03 | HT-OBS-03 |
| HU-OBS-04 | HT-OBS-04 |
| HU-OBS-05 | HT-OBS-05 |
