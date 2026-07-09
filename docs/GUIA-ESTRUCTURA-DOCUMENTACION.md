# Guía de estructura documental — ShopDemo

Documentación de requisitos organizada en **tres capas** para distintas audiencias.

---

## Las tres capas

| Capa | Documento | Audiencia | Contenido |
|---|---|---|---|
| **A — Negocio** | `REQUERIMIENTOS-*.md` | PM, analista, negocio, junior que entiende el dominio | Propósito, resumen llano, alcance, reglas RN-*, RF-* en lenguaje de negocio, criterios CA-N |
| **A — Negocio** | `HISTORIAS-USUARIO-*.md` | Igual | Historias *Como [persona de negocio]…* con reglas y CA-N |
| **B — Técnica** | `ANEXO-ESPECIFICACION-TECNICA-*.md` | Desarrollador implementador | API, dominio, capas, stack, puertos, persistencia, CA-T |
| **B — Técnica** | `ANEXO-HISTORIAS-TECNICAS-*.md` | Desarrollador / DevOps | Tareas de implementación, infra, arquitectura |
| **C — Pedagogía** | `ANEXO-PEDAGOGIA-*.md` | Instructor y alumno | Objetivos de aprendizaje, entregables, reflexión |

---

## Orden de lectura recomendado

### Para negocio o junior sin contexto técnico

1. `REQUERIMIENTOS-*.md` — sección *Resumen en lenguaje llano*
2. `HISTORIAS-USUARIO-*.md`
3. (Opcional) `RETO-TECNICO-SHOPDEMO.md`

### Para desarrollador que implementa

1. `REQUERIMIENTOS-*.md` — contexto de negocio
2. `HISTORIAS-USUARIO-*.md` — qué debe lograr el sistema
3. `ANEXO-ESPECIFICACION-TECNICA-*.md` — cómo construirlo
4. `ANEXO-HISTORIAS-TECNICAS-*.md` — tareas técnicas detalladas
5. `IMPLEMENTACION-*.md` — guía paso a paso
6. `ANEXO-PEDAGOGIA-*.md` — solo si eres alumno del curso

---

## Convenciones de identificadores

| Prefijo | Capa | Ejemplo |
|---|---|---|
| `RF-*` | Negocio | Requerimiento funcional |
| `RN-*` | Negocio | Regla de negocio |
| `HU-*` | Negocio | Historia de usuario |
| `CA-N*` | Negocio | Criterio de aceptación verificable por negocio/QA |
| `CA-T*` | Técnica | Criterio de aceptación de implementación |
| `OBJ-*` | Pedagogía / negocio | Objetivo del módulo o del curso |
| `RNF-*` | Técnica | Requerimiento no funcional |

---

## Módulos con esta estructura

| Módulo | Carpeta |
|---|---|
| Catalog | `docs/catalog/` |
| Orders | `docs/orders/` |
| Inventory | `docs/inventory/` |
| Analytics / Aspire | `docs/analytics/` |
| Despliegue Azure | `docs/despliegue/azure/` |
| Despliegue AWS | `docs/despliegue/aws/` |
| Kubernetes local | `docs/despliegue/kubernetes/` |
| AKS | `docs/despliegue/aks/` |
| EKS | `docs/despliegue/eks/` |
| Observabilidad | `docs/observabilidad/` |
| Resiliencia | `docs/resiliencia/` |
| Integración IA | `docs/integracion-ia/` |
| Despliegue MCP | `docs/integracion-ia/` |
| Spec-driven | `spec-driven/` |
