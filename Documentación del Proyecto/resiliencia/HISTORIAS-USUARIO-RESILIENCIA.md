# Historias de Usuario — Resiliencia (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-RESILIENCIA.md](./REQUERIMIENTOS-RESILIENCIA.md) |

---

## HU-RES-01 — Recuperación automática de servicios

| **RF** | RF-RES-01 · **OBJ** | OBJ-RES-01 |

**Como** operador de la tienda, **quiero** que un servicio caído se restablezca solo, **para** no detener ventas por un reinicio puntual.

### Criterios (CA-N)

- [ ] **CA-N-RES-01:** Servicio vuelve a Ready/Running tras fallo simulado.

---

## HU-RES-02 — Enrutar solo a instancias sanas

| **RF** | RF-RES-02 · **OBJ** | OBJ-RES-02 |

**Como** equipo de soporte, **quiero** que el balanceador/orquestador excluya instancias no saludables, **para** evitar errores al cliente.

### Criterios (CA-N)

- [ ] **CA-N-RES-02:** Health probes configurados en 4 servicios.

---

## HU-RES-03 — Mantener redundancia y escalar

| **RF** | RF-RES-03 · **OBJ** | OBJ-RES-03, OBJ-RES-05 |

**Como** responsable de TI, **quiero** réplicas mínimas y escalado bajo carga, **para** absorber picos sin caída total.

### Criterios (CA-N)

- [ ] **CA-N-RES-04:** HPA o escalado manual demostrado.

---

## HU-RES-04 — Entender fallos síncronos y asíncronos

| **RF** | RF-RES-05 · **OBJ** | OBJ-RES-04 |

**Como** equipo de soporte, **quiero** explicar qué ocurre si falla inventario vs Event Hubs, **para** priorizar incidentes correctamente.

### Reglas

| ID | Regla |
|---|---|
| RN-RES-03 | Impacto distinto según tipo de comunicación |

### Criterios (CA-N)

- [ ] **CA-N-RES-03:** Explicación documentada.

---

## HU-RES-05 — Actualizar sin caída total

| **RF** | RF-RES-04 · **OBJ** | OBJ-RES-06 |

**Como** responsable de TI, **quiero** rolling updates en ACA/ECS/K8s, **para** desplegar versiones sin apagar toda la tienda.

### Criterios (CA-N)

- [ ] **CA-N-RES-05:** Guías Azure y AWS completadas.

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-RESILIENCIA.md](./ANEXO-HISTORIAS-TECNICAS-RESILIENCIA.md).
