# Historias de Usuario — Despliegue Azure Container Apps (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./REQUERIMIENTOS-DESPLIEGUE-AZURE.md) |
| **Persona** | Alumno DevOps / Desarrollador .NET |

---

## HU-AZ-01 — Publicar imágenes en ACR

| **Objetivo** | OBJ-AZ-01 |

**Como** alumno, **quiero** subir las 5 imágenes Docker a ACR, **para** que Container Apps las ejecuten.

**Modelo:** **N/A** (infraestructura); artefactos: Dockerfile, tags `shopdemo-*`.

**Reglas:** RNF-AZ-03 — secretos no en git.

**Criterios:**
- [ ] 5 repos/tags en ACR (`catalog`, `orders`, `inventory`, `analytics`, `mcp`).
- [ ] Login ACR con `az acr login` exitoso.

---

## HU-AZ-02 — Desplegar APIs en Container Apps

| **Objetivo** | OBJ-AZ-02 · **RF** | RF-AZ-01 a RF-AZ-04 |

**Como** alumno, **quiero** 5 Container Apps en un Environment, **para** exponer el release serverless.

**Modelo:** Secretos ACA (connection strings, Event Hubs, Storage checkpoints); **N/A** entidad.

**Reglas:**
- RN-AZ-01: Ingress externo Catalog, Orders, Analytics, MCP; Inventory interno.
- RN-AZ-02: Checkpoints en **Storage Account** (no Azurite en ACA).

**Criterios (CA-AZ-01, CA-AZ-02):**
- [ ] Apps en estado Running.
- [ ] Swagger/health en FQDN Catalog.

---

## HU-AZ-03 — PostgreSQL en contenedor (ACI)

| **Objetivo** | OBJ-AZ-03 |

**Como** lab, **quiero** PostgreSQL en ACI con 3 bases, **para** no usar Azure Database gestionado.

**Reglas:** RN-AZ-03 — datos efímeros si se recrea ACI (documentado).

**Criterios:** Connection strings en secrets ACA apuntan a FQDN ACI.

---

## HU-AZ-04 — Integración Event Hubs y Orders→Inventory

| **Objetivos** | OBJ-AZ-04, OBJ-AZ-05 · **RF** | RF-AZ-02, RF-AZ-03 |

**Criterios (CA-AZ-03, CA-AZ-04):**
- [ ] Crear producto → evento en Analytics.
- [ ] Confirmar pedido sin error de URL Inventory interna.

---

## HU-AZ-05 — Actualizar release (CI/CD)

| **Objetivo** | OBJ-AZ-07 · **RF** | RF-AZ-05 |

**Como** alumno, **quiero** push nueva imagen + revisión ACA, **para** desplegar cambios.

**Criterios:** Workflow `deploy-azure.yml` o push manual documentado.

---

## HU-AZ-06 — Documentación dual Portal + CLI

| **Objetivo** | OBJ-AZ-06 |

**Criterio (CA-AZ-05):** Alumno completó al menos un paso equivalente en Portal y CLI.

**Referencias:** [GUIA-RELEASE-PORTAL-AZURE.md](../azure/GUIA-RELEASE-PORTAL-AZURE.md) · [GUIA-RELEASE-SCRIPT-AZURE.md](../azure/GUIA-RELEASE-SCRIPT-AZURE.md)
