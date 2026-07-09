# Historias de Usuario — Observabilidad (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-OBSERVABILIDAD.md](./REQUERIMIENTOS-OBSERVABILIDAD.md) |

---

## HU-OBS-01 — Centralizar logs en nube

| **RF** | RF-OBS-01 · **OBJ** | OBJ-OBS-02 |

**Como** equipo de soporte, **quiero** ver logs de catálogo, pedidos, inventario y analítica en un solo panel, **para** diagnosticar sin entrar a cada contenedor.

### Criterios (CA-N)

- [ ] **CA-N-OBS-01:** Logs visibles de las 4 APIs.

---

## HU-OBS-02 — Consultar métricas de salud

| **OBJ** | OBJ-OBS-03 |

**Como** responsable de TI, **quiero** métricas de CPU, reinicios y latencia HTTP, **para** detectar degradación temprana.

### Criterios (CA-N)

- [ ] Métricas localizables en portal cloud por servicio.

---

## HU-OBS-03 — Correlacionar peticiones fallidas

| **RF** | RF-OBS-02, RF-OBS-03 · **OBJ** | OBJ-OBS-01, OBJ-OBS-04 |

**Como** equipo de soporte, **quiero** buscar logs por identificador de rastreo de una respuesta de error, **para** seguir el flujo de un pedido fallido.

### Reglas

| ID | Regla |
|---|---|
| RN-OBS-01 | Identificador presente en respuesta de error |

### Criterios (CA-N)

- [ ] **CA-N-OBS-02:** Investigación documentada con traceId real.

---

## HU-OBS-04 — Configurar alertas proactivas

| **RF** | RF-OBS-04 · **OBJ** | OBJ-OBS-05 |

**Como** responsable de TI, **quiero** alertas por errores 5xx o CPU alta, **para** actuar antes del reporte del operador.

### Reglas

| ID | Regla |
|---|---|
| RN-OBS-03 | Alerta probada antes de cerrar módulo |

### Criterios (CA-N)

- [ ] **CA-N-OBS-03:** Al menos una alerta creada y probada.

---

## HU-OBS-05 — Investigar incidente E2E

| **RF** | RF-OBS-05 · **OBJ** | OBJ-OBS-06 |

**Como** equipo de soporte, **quiero** una guía de investigación reproducible, **para** identificar el servicio afectado en flujos completos.

### Criterios (CA-N)

- [ ] **CA-N-OBS-04:** Flujo investigación E2E reproducido.
- [ ] **CA-N-OBS-05:** Documentación ACA, AKS, ECS, EKS.

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md](./ANEXO-HISTORIAS-TECNICAS-OBSERVABILIDAD.md).
