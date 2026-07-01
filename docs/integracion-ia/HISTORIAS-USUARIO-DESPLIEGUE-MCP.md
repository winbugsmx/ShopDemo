# Historias de Usuario — Despliegue MCP Gateway (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md) |

---

## HU-MCP-01 — Empaquetar MCP en Docker

| **Objetivo** | OBJ-MCP-01 |

**Como** pipeline CI, **quiero** imagen `shopdemo-mcp`, **para** desplegar igual que las otras APIs.

**Modelo:** Dockerfile en `AI/ShopDemo.Mcp.Api/`; **N/A** entidad.

**Criterios:** Build desde raíz repo exitoso.

---

## HU-MCP-02 — Desplegar en Azure (ACA + AKS)

| **Objetivos** | OBJ-MCP-02, OBJ-MCP-03 |

**Como** agente externo, **quiero** URL `/mcp` en nube Azure, **para** tools en lab ACA o Ingress AKS.

**Reglas:** Env vars `ShopDemo__*ApiBaseUrl`; health probe `/health`.

**Criterios (CA-MCP-01, CA-MCP-04):** curl health 200; pod Running en AKS.

---

## HU-MCP-03 — Desplegar en AWS (ECS + EKS)

| **Objetivos** | OBJ-MCP-04, OBJ-MCP-05 |

**Reglas:** ALB MCP en ECS; en EKS: `k8s/aws/mcp/deployment.yaml` + `k8s/mcp/service.yaml`.

**Criterios (CA-MCP-02):** Agente lista tools contra URL pública.

---

## HU-MCP-04 — CI/CD y documentación dual

| **Objetivos** | OBJ-MCP-06, OBJ-MCP-07 |

**Criterios (CA-MCP-03, CA-MCP-05):** `GetShopDemoStatus` OK; workflow actualiza ACR/ECR.

**Dependencia:** 4 APIs de negocio ya desplegadas y alcanzables.
