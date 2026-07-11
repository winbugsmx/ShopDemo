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
| Catalog | `Documentación_Del_Proyecto/catalog/` |
| Orders | `Documentación_Del_Proyecto/orders/` |
| Inventory | `Documentación_Del_Proyecto/inventory/` |
| Analytics / Aspire | `Documentación_Del_Proyecto/analytics/` |
| Despliegue Azure | `Documentación_Del_Proyecto/despliegue/azure/` |
| Despliegue AWS | `Documentación_Del_Proyecto/despliegue/aws/` |
| Kubernetes local | `Documentación_Del_Proyecto/despliegue/kubernetes/` |
| AKS | `Documentación_Del_Proyecto/despliegue/aks/` |
| EKS | `Documentación_Del_Proyecto/despliegue/eks/` |
| Observabilidad | `Documentación_Del_Proyecto/observabilidad/` |
| Resiliencia | `Documentación_Del_Proyecto/resiliencia/` |
| Integración IA | `Documentación_Del_Proyecto/integracion-ia/` |
| Despliegue MCP | `Documentación_Del_Proyecto/integracion-ia/` |
| Spec-driven | `spec-driven/` |
