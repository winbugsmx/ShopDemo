# Anexo — Pedagogía: Despliegue MCP (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Capa** | C — Objetivos del curso |

---

## 1. Objetivos de aprendizaje

1. Empaquetar MCP Gateway en **Docker**.
2. Desplegar MCP en **ACA y AKS** (Azure).
3. Desplegar MCP en **ECS y EKS** (AWS).
4. Configurar **Ingress `/mcp`** y variables de APIs.
5. Integrar MCP en **workflows CI/CD**.

---

## 2. Tiempo estimado

| Actividad | Duración |
|---|---|
| Docker + local validado | 30 min (prerequisito) |
| MCP en 1 plataforma nube | 1–1.5 h |
| MCP en 2ª plataforma misma cloud | 45 min |
| Segunda cloud completa | 2–3 h |
| **Total despliegue MCP** | **4–6 h** (acumulado tras APIs) |

---

## 3. Entregables

| # | Entregable |
|---|---|
| 1 | Imagen `shopdemo-mcp` en ACR y/o ECR |
| 2 | curl `/health` 200 en nube |
| 3 | Agente listando tools en URL pública |
| 4 | Pod/deployment MCP Running en K8s (si aplica) |

---

## 4. Prerequisitos

- 4 APIs de negocio desplegadas
- [IMPLEMENTACION-MCP-GATEWAY.md](./IMPLEMENTACION-MCP-GATEWAY.md) local completado

---

## 5. Referencias

- [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md)
