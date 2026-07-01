# Historias de Usuario — Observabilidad (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Fuente** | [REQUERIMIENTOS-OBSERVABILIDAD.md](./REQUERIMIENTOS-OBSERVABILIDAD.md) |
| **Persona** | Alumno SRE / DevOps |

---

## HU-OBS-01 — Centralizar logs en nube

| **Objetivo** | OBJ-OBS-01, OBJ-OBS-05 |

**Como** operador, **quiero** ver logs de las 4 APIs en Log Analytics o CloudWatch, **para** diagnosticar sin entrar a cada contenedor.

**Modelo:** **N/A** — configuración plataforma + `traceId` en middleware existente.

**Criterios (CA-OBS-01):** Logs visibles de Catalog, Orders, Inventory, Analytics.

---

## HU-OBS-02 — Consultar métricas HTTP e infra

| **Objetivo** | OBJ-OBS-02 |

**Como** operador, **quiero** métricas de CPU, reinicios y latencia, **para** detectar degradación.

**Modelo:** **N/A**.

**Criterios:** Alumno localiza métrica de al menos un servicio en portal cloud.

---

## HU-OBS-03 — Correlacionar con traceId

| **Objetivo** | OBJ-OBS-03, OBJ-OBS-06 |

**Como** alumno, **quiero** buscar logs por `traceId` de una respuesta error, **para** seguir una petición E2E.

**Reglas:** Usar `ExceptionHandlingMiddleware` existente.

**Criterios (CA-OBS-03):** Investigación documentada con traceId real.

---

## HU-OBS-04 — Configurar alerta básica

| **Objetivo** | OBJ-OBS-04 |

**Como** operador, **quiero** alerta por 5xx o CPU alta, **para** simular operación proactiva.

**Modelo:** **N/A** — regla KQL o Logs Insights.

**Criterios (CA-OBS-02):** Alerta creada y probada (disparo simulado o umbral real).

---

## HU-OBS-05 — Cubrir las 4 plataformas de cómputo

| **Objetivo** | OBJ-OBS-07 |

**Criterios (CA-OBS-04, CA-OBS-05):** Guías ACA, AKS, ECS, EKS completadas; flujo investigación E2E reproducido.
