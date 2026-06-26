# Historias de Usuario — Integración de IA (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-INTEGRACION-IA.md](./REQUERIMIENTOS-INTEGRACION-IA.md) |

---

## HU-IA-01 — Alertas de anomalías en logs

| **Objetivo** | OBJ-IA-01 |

**Como** operador, **quiero** alertas KQL/Logs Insights por umbral, **para** detectar picos de errores sin ML custom.

**Modelo:** **N/A** — consultas y reglas cloud.

**Criterios (CA-IA-01):** Al menos 1 alerta activa y probada.

---

## HU-IA-02 — MCP Gateway local

| **Objetivo** | OBJ-IA-02 |

**Como** agente IA, **quiero** conectar a `/mcp` del gateway, **para** invocar tools sobre ShopDemo.

**Modelo:** **DTO** tools MCP; servicio `ShopDemo.Mcp.Api` (sin agregado dominio).

**Reglas:** 4 tools documentadas; delegación HTTP a APIs.

**Criterios (CA-IA-02, CA-IA-03):** `/health` 200; agente lista e invoca tool.

---

## HU-IA-03 — Documentar Semantic Kernel + Event Hubs

| **Objetivo** | OBJ-IA-03, OBJ-IA-04 |

**Como** alumno, **quiero** diseño SK consumiendo eventos, **para** entender enriquecimiento con LLM.

**Modelo:** Pseudocódigo + paquetes NuGet (**N/A** worker en repo).

**Criterios (CA-IA-04):** Documento describe flujo Event Hubs → LLM → publicación.

---

## HU-IA-04 — Guías multicloud IA

| **Objetivo** | OBJ-IA-05 |

**Criterios (CA-IA-05):** Implementación Azure y AWS MCP/alertas documentadas.

---

## HU-IA-05 — OpenAI como LLM común

| **Objetivo** | OBJ-IA-06 |

**Reglas:** API key en secreto; no commitear.

**Modelo:** Configuración env var / user secrets.
