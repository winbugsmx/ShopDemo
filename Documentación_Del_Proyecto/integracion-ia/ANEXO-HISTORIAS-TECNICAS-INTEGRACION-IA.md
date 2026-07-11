# Anexo — Historias técnicas: Integración IA (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-IA-01 — Implementar MCP Gateway local

| **HU** | HU-IA-02 |

**Como** alumno, **quiero** `ShopDemo.Mcp.Api` con 4 tools, **para** exponer `/mcp`.

### Criterios (CA-T)

- [ ] **CA-T-IA-01, CA-T-IA-02, CA-T-IA-03**

---

## HT-IA-02 — Conectar agente (Cursor u otro)

| **HU** | HU-IA-02 |

**Como** alumno, **quiero** configurar MCP en cliente IA, **para** invocar tools.

---

## HT-IA-03 — Configurar alerta KQL / Logs Insights

| **HU** | HU-IA-01 |

**Como** alumno, **quiero** regla de alerta por umbral, **para** cumplir OBJ-IA-01.

### Criterios (CA-T)

- [ ] **CA-T-IA-04**

---

## HT-IA-04 — Documentar Semantic Kernel + Event Hubs

| **HU** | HU-IA-03 |

**Como** alumno, **quiero** documento con flujo y pseudocódigo SK, **para** diseño enriquecimiento.

### Criterios (CA-T)

- [ ] **CA-T-IA-05**

---

## HT-IA-05 — Guías multicloud

| **HU** | HU-IA-04 |

**Como** alumno, **quiero** completar guías Azure y AWS de alertas, **para** lab multicloud.

### Referencias

- [azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md](./azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md)
- [aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md](./aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md)

---

## Trazabilidad

| HU | HT |
|---|---|
| HU-IA-01 | HT-IA-03 |
| HU-IA-02 | HT-IA-01, HT-IA-02 |
| HU-IA-03 | HT-IA-04 |
| HU-IA-04 | HT-IA-05 |

Despliegue MCP en nube: [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md).
