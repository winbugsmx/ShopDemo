# Historias de Usuario — Despliegue MCP Gateway (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md) |

---

## HU-MCP-01 — Consultar tienda desde agente en nube

| **RF** | RF-MCP-01, RF-MCP-02 |

**Como** responsable de operaciones, **quiero** conectar un agente a `/mcp` en la nube, **para** invocar herramientas sin entorno local.

### Criterios (CA-N)

- [ ] **CA-N-MCP-02:** Agente lista herramientas.
- [ ] **CA-N-MCP-03:** `GetShopDemoStatus` reporta APIs OK.

---

## HU-MCP-02 — Verificar disponibilidad del gateway

| **RF** | RF-MCP-03 |

**Como** equipo de soporte, **quiero** consultar salud del gateway, **para** aislar fallos MCP vs APIs de negocio.

### Criterios (CA-N)

- [ ] **CA-N-MCP-01:** `/health` responde 200 en cada plataforma.

---

## HU-MCP-03 — Mantener gateway actualizado

| **RF** | RF-MCP-04 |

**Como** responsable de TI, **quiero** actualizar imagen MCP con el release, **para** mantener herramientas al día.

### Reglas

| ID | Regla |
|---|---|
| RN-MCP-05 | APIs de negocio desplegadas primero |

---

## HU-MCP-04 — Desplegar en todas las plataformas lab

| **RF** | RF-MCP-03 |

**Como** responsable de TI, **quiero** MCP en ACA, AKS, ECS y EKS, **para** paridad multicloud.

### Criterios (CA-N)

- [ ] **CA-N-MCP-04:** `/mcp` accesible en cada plataforma documentada.

---

Implementación: [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md).
