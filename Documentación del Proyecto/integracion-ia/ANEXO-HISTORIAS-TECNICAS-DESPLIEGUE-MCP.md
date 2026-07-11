# Anexo — Historias técnicas: Despliegue MCP (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | B — Tareas de implementación |

---

## HT-MCP-01 — Empaquetar MCP en Docker

| **HU** | HU-MCP-03 |

**Como** alumno, **quiero** imagen `shopdemo-mcp` desde raíz repo, **para** pipeline CI.

```bash
docker build -f Source/AI/ShopDemo.Mcp.Api/Dockerfile -t shopdemo-mcp:latest .
```

---

## HT-MCP-02 — Desplegar en Azure ACA

| **HU** | HU-MCP-01, HU-MCP-02 |

**Como** alumno, **quiero** Container App MCP con env vars APIs, **para** `/mcp` público.

### Criterios (CA-T)

- [ ] **CA-T-MCP-01** (ACA)

---

## HT-MCP-03 — Desplegar en AKS

| **HU** | HU-MCP-04 |

**Como** alumno, **quiero** apply `k8s/azure/mcp/` + service + ingress, **para** pod Running.

### Criterios (CA-T)

- [ ] **CA-T-MCP-03, CA-T-MCP-05**

---

## HT-MCP-04 — Desplegar en ECS

| **HU** | HU-MCP-01 |

**Como** alumno, **quiero** ECS service MCP con ALB, **para** tools en AWS serverless.

---

## HT-MCP-05 — Desplegar en EKS

| **HU** | HU-MCP-04 |

**Como** alumno, **quiero** `k8s/aws/mcp/deployment.yaml`, **para** paridad con AKS.

---

## HT-MCP-06 — CI/CD y validación agente

| **HU** | HU-MCP-03 |

**Como** alumno, **quiero** workflows actualizando ACR/ECR, **para** release automatizado.

### Criterios (CA-T)

- [ ] **CA-T-MCP-02, CA-T-MCP-04**

### Referencias

- [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

---

## Trazabilidad

| HU | HT |
|---|---|
| HU-MCP-01 | HT-MCP-02, HT-MCP-04, HT-MCP-06 |
| HU-MCP-02 | HT-MCP-02, HT-MCP-03 |
| HU-MCP-03 | HT-MCP-01, HT-MCP-06 |
| HU-MCP-04 | HT-MCP-03, HT-MCP-05 |
