# Historias de Usuario — Despliegue AWS ECS Fargate (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./REQUERIMIENTOS-DESPLIEGUE-AWS.md) |
| **Persona** | Alumno DevOps |

---

## HU-AW-01 — Configurar IAM y credenciales

**Como** alumno, **quiero** un usuario IAM con permisos de lab, **para** crear VPC, ECS, ECR y SSM sin errores AccessDenied.

**Reglas:** Máx. 10 políticas → usar `ShopDemoLabECS` (1 policy).

**Modelo:** **N/A** — política IAM JSON en `scripts/aws/`.

**Criterios:** `aws sts get-caller-identity` exitoso.

---

## HU-AW-02 — Publicar imágenes en ECR

| **Objetivo** | OBJ-AW-01 · **RF** | RF-AW-04 |

**Como** alumno, **quiero** build y push desde mi PC, **para** que ECS descargue imágenes privadas.

**Reglas:** Push **no** se hace desde consola AWS; requiere Docker + CLI.

**Criterios (CA-AW-01):**
- [ ] 5 repos con tag `latest`.
- [ ] Force new deployment si tasks estaban STOPPED.

**Referencia:** [GUIA-RELEASE-PORTAL-AWS §12](../aws/GUIA-RELEASE-PORTAL-AWS.md#12-publicar-imágenes-en-ecr)

---

## HU-AW-03 — Red VPC y security groups

**Como** plataforma, **quiero** VPC con subnets públicas y 3 SG, **para** aislar ALB, apps y datos.

**Modelo:** **N/A** infra.

**Criterios:** Tráfico ALB→apps:8080; apps→postgres:5432; apps→azurite:10000.

---

## HU-AW-04 — PostgreSQL y secretos SSM

**Como** ECS task de APIs, **quiero** connection strings en SSM, **para** conectar a Postgres sin texto plano en task definition.

**Reglas:**
- RN-AW-01: Host en SSM = **IP privada** de task Postgres (no pública).
- RN-AW-02: Tras reinicio Postgres, actualizar `/shopdemo/pg-*`.

**Modelo:** Parámetros SecureString; **N/A** DTO.

**Criterios:** 3 parámetros pg-* con bases correctas.

---

## HU-AW-05 — Desplegar APIs con ALB y Cloud Map

| **Objetivos** | OBJ-AW-02, OBJ-AW-04 · **RF** | RF-AW-01, RF-AW-03 |

**Como** cliente HTTP, **quiero** ALB por API pública, **para** acceder a Catalog/Orders/Analytics/MCP.

**Como** Orders, **quiero** resolver `inventory.shopdemo.local`, **para** confirmar pedidos.

**Criterios (CA-AW-02, CA-AW-04):**
- [ ] Swagger Catalog vía DNS ALB.
- [ ] Confirmación pedido exitosa.

---

## HU-AW-06 — Integración cross-cloud Event Hubs

| **Objetivo** | OBJ-AW-05 · **RF** | RF-AW-02 |

**Reglas:** RNF-AW-03 — egress 443 hacia Azure; connection string en SSM `/shopdemo/eh-connection`.

**Criterios (CA-AW-03):** Analytics lista eventos tras crear producto.

---

## HU-AW-07 — Documentación Consola + CLI

| **Objetivo** | OBJ-AW-06 |

**Criterio (CA-AW-05):** Pasos equivalentes en Portal y CLI documentados.
