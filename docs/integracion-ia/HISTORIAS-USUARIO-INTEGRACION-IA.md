# Historias de Usuario — Integración de IA (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-INTEGRACION-IA.md](./REQUERIMIENTOS-INTEGRACION-IA.md) |

---

## HU-IA-01 — Recibir alertas de anomalías

| **RF** | RF-IA-01 · **OBJ** | OBJ-IA-01 |

**Como** equipo de soporte, **quiero** alertas por picos de errores o CPU, **para** actuar antes de que el operador reporte fallos.

### Criterios (CA-N)

- [ ] **CA-N-IA-01:** Al menos una alerta activa y probada.

---

## HU-IA-02 — Consultar tienda con agente IA

| **RF** | RF-IA-02 · **OBJ** | OBJ-IA-02 |

**Como** responsable de operaciones, **quiero** que un agente invoque herramientas sobre ShopDemo, **para** obtener estado, productos o eventos sin usar cada API manualmente.

### Reglas

| ID | Regla |
|---|---|
| RN-IA-01 | Gateway delega en APIs; no sustituye dominio |

### Criterios (CA-N)

- [ ] **CA-N-IA-02:** Agente lista e invoca herramienta con respuesta coherente.

---

## HU-IA-03 — Entender enriquecimiento con IA

| **RF** | RF-IA-03 · **OBJ** | OBJ-IA-03 |

**Como** responsable de TI, **quiero** documentación del flujo Semantic Kernel con eventos, **para** planificar enriquecimiento futuro de mensajes de negocio.

### Criterios (CA-N)

- [ ] **CA-N-IA-03:** Documento describe Event Hubs → LLM → publicación.

---

## HU-IA-04 — Operar integración IA multicloud

| **RF** | RF-IA-04 · **OBJ** | OBJ-IA-04 |

**Como** responsable de TI, **quiero** guías separadas Azure y AWS, **para** replicar alertas y MCP en cada nube del lab.

### Criterios (CA-N)

- [ ] **CA-N-IA-04:** Implementación Azure y AWS documentadas.

---

## HU-IA-05 — Proteger credenciales LLM

| **RF** | RF-IA-05 · **OBJ** | OBJ-IA-05 |

**Como** responsable de TI, **quiero** API keys en secretos, **para** cumplir política de seguridad.

### Reglas

| ID | Regla |
|---|---|
| RN-IA-03 | Worker SK opcional; diseño en docs |

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md](./ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md) · Despliegue MCP: [HISTORIAS-USUARIO-DESPLIEGUE-MCP.md](./HISTORIAS-USUARIO-DESPLIEGUE-MCP.md).
