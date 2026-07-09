# Anexo — Historias técnicas: Despliegue AWS (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Historias de negocio** | [HISTORIAS-USUARIO-DESPLIEGUE-AWS.md](./HISTORIAS-USUARIO-DESPLIEGUE-AWS.md) |
| **Especificación** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md) |
| **Capa** | B — Tareas de implementación |

---

## HT-AW-01 — Configurar IAM y credenciales

**Como** alumno, **quiero** usuario IAM con `ShopDemoLabECS`, **para** crear VPC, ECS, ECR y SSM.

### Criterios (CA-T)

- [ ] `aws sts get-caller-identity` exitoso.

---

## HT-AW-02 — Publicar imágenes en ECR

| **Historia negocio** | HU-AW-01 |

**Como** desarrollador, **quiero** build y push de 5 imágenes a ECR, **para** que ECS las descargue.

### Tareas

1. `aws ecr get-login-password | docker login`
2. Build y push `shopdemo-catalog`, `orders`, `inventory`, `analytics`, `mcp`

### Criterios (CA-T)

- [ ] **CA-T-AW-02:** 5 repos con tag `latest`.

---

## HT-AW-03 — Red VPC y security groups

**Como** desarrollador, **quiero** VPC con subnets y 3 SG, **para** aislar ALB, apps y datos.

### Criterios (CA-T)

- [ ] Tráfico ALB→apps:8080; apps→postgres:5432; apps→azurite:10000.

---

## HT-AW-04 — PostgreSQL, Azurite y secretos SSM

| **Historia negocio** | HU-AW-03 |

**Como** desarrollador, **quiero** connection strings en SSM SecureString, **para** evitar texto plano en task definitions.

### Reglas técnicas

- RN-AW-03: Tras reinicio Postgres, actualizar `/shopdemo/pg-*` con IP privada.

### Criterios (CA-T)

- [ ] 3 parámetros pg-* con bases correctas.

---

## HT-AW-05 — Desplegar APIs con ALB y Cloud Map

| **Historias negocio** | HU-AW-01, HU-AW-03 |

**Como** desarrollador, **quiero** ALB por API pública y Cloud Map para Inventory, **para** que Orders confirme pedidos.

### Criterios (CA-T)

- [ ] **CA-T-AW-03:** Swagger Catalog vía ALB.
- [ ] **CA-T-AW-04:** Confirmación pedido exitosa.

---

## HT-AW-06 — Integración cross-cloud Event Hubs

| **Historia negocio** | HU-AW-02 |

**Como** desarrollador, **quiero** `EventHubs__ConnectionString` en SSM, **para** eventos hacia Analytics.

### Criterios (CA-T)

- [ ] **CA-T-AW-05:** Analytics lista eventos tras crear producto.

---

## HT-AW-07 — Pipeline y documentación dual

| **Historia negocio** | HU-AW-04 |

### Referencias

- [GUIA-RELEASE-PORTAL-AWS.md](./GUIA-RELEASE-PORTAL-AWS.md)
- [GUIA-RELEASE-CLI-AWS.md](./GUIA-RELEASE-CLI-AWS.md)

### Criterios (CA-T)

- [ ] **CA-T-AW-07:** Workflow actualiza ECR/ECS.

---

## Trazabilidad

| Historia negocio | Historias técnicas |
|---|---|
| HU-AW-01 | HT-AW-02, HT-AW-05 |
| HU-AW-02 | HT-AW-06 |
| HU-AW-03 | HT-AW-04, HT-AW-05 |
| HU-AW-04 | HT-AW-07 |
