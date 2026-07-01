# Teoría para entrevistas técnicas — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Propósito** | Estudiar la **teoría implementada** en ShopDemo como guía de aprendizaje y preparación para entrevistas |

Esta carpeta **no sustituye** la práctica del lab; complementa los documentos de implementación con conceptos, patrones y preguntas típicas de entrevista, **anclados al código real** del repositorio.

---

## Orden de lectura recomendado

| # | Documento | Tiempo | Qué dominarás |
|---|---|---|---|
| 1 | [01-patrones-diseno.md](./01-patrones-diseno.md) | 45 min | Patrones en Catalog, Orders, Inventory |
| 2 | [02-arquitecturas-software.md](./02-arquitecturas-software.md) | 60 min | Clean vs Hexagonal vs microservicios |
| 3 | [03-ddd-y-bounded-contexts.md](./03-ddd-y-bounded-contexts.md) | 45 min | DDD táctico y contextos |
| 4 | [04-comunicacion-microservicios.md](./04-comunicacion-microservicios.md) | 50 min | HTTP, Event Hubs, consistencia |
| 5 | [05-servicios-azure.md](./05-servicios-azure.md) | 40 min | ACA, AKS, ACR, Event Hubs |
| 6 | [06-servicios-aws.md](./06-servicios-aws.md) | 40 min | ECS, EKS, ECR, cross-cloud |
| 7 | [07-kubernetes-cloud-native.md](./07-kubernetes-cloud-native.md) | 50 min | K8s, Ingress, HPA, manifiestos |
| 8 | [08-ci-cd-devops.md](./08-ci-cd-devops.md) | 35 min | GitHub Actions, environments |
| 9 | [09-integracion-ia-mcp.md](./09-integracion-ia-mcp.md) | 30 min | MCP Gateway y agentes |
| 10 | [11-observabilidad-resiliencia.md](./11-observabilidad-resiliencia.md) | 55 min | Pilares OTEL, probes, HPA, incidentes |
| 11 | [10-preguntas-entrevista.md](./10-preguntas-entrevista.md) | 60 min | Flashcards integradas (repaso final) |

---

## Rutas según tipo de entrevista

| Enfoque | Lee primero | Luego |
|---|---|---|
| Backend .NET / DDD | 01 → 02 → 03 → 04 | 10 |
| Cloud Azure | 05 → 07 → 08 | 04 |
| Cloud AWS | 06 → 07 → 08 | 04 |
| DevOps / SRE | 07 → 08 → **11** → 05 → 06 | 10 |
| Observabilidad / resiliencia | **11** → 07 → 04 | 10 |
| Arquitecto | 02 → 03 → 04 → 05 → 06 | 09 → **11** → 10 |

---

## Recursos gráficos

| Recurso | Ubicación |
|---|---|
| Fuentes Mermaid | [assets/diagrams/](./assets/diagrams/) |
| draw.io / imágenes | [assets/RECURSOS-GRAFICOS.md](./assets/RECURSOS-GRAFICOS.md) |

---

## Documentación relacionada

| Tema | Enlace |
|---|---|
| Arquitectura | [docs/ARQUITECTURA.md](../ARQUITECTURA.md) |
| Observabilidad / resiliencia (detalle) | [TEORIA-OBSERVABILIDAD.md](../observabilidad/TEORIA-OBSERVABILIDAD.md) · [TEORIA-RESILIENCIA.md](../resiliencia/TEORIA-RESILIENCIA.md) |
| Examen / reto | [EXAMEN-TEORICO-SHOPDEMO.md](../EXAMEN-TEORICO-SHOPDEMO.md) |

---

## Método de estudio

1. Lee un documento (30–45 min).
2. Ubica 2–3 archivos citados en el repo.
3. Responde las preguntas del doc sin mirar.
4. Repasa con el documento **10** (flashcards finales).
5. Explica el flujo E2E en voz alta (< 3 min).
