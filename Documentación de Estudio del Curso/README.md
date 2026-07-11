# Tópicos de Estudio — Material de aprendizaje

Bienvenido. Esta guía está escrita **como si asistieras a un curso de arquitectura de software** dirigido a desarrolladores que ya programan (por ejemplo, en C# y ASP.NET) pero que aún no dominan patrones, arquitecturas distribuidas ni plataformas cloud.

| Campo | Detalle |
|:------|:--------|
| **Propósito** | Aprender teoría con definiciones completas, explicaciones progresivas y diagramas |
| **Audiencia** | Desarrollador junior / intermedio inicial |
| **Prerrequisitos** | Programación básica, HTTP, bases de datos relacionales, nociones de API REST |
| **Formato** | Definición → explicación → diagrama → ejemplo → cuándo usar / cuándo no |

> **Cómo leer cada capítulo:** no te saltes las definiciones. En arquitectura, muchos malentendidos vienen de usar palabras (como “microservicio” o “agregado”) sin conocer su significado preciso. Cada sección construye sobre la anterior.

---

## Orden de lectura recomendado

| # | Documento | Qué aprenderás |
|---|---|---|
| 1 | [01-patrones-diseno.md](./01-patrones-diseno.md) | Qué es un patrón; GoF; patrones enterprise |
| 2 | [02-arquitecturas-software.md](./02-arquitecturas-software.md) | Capas, Clean, Hexagonal, microservicios |
| 3 | [03-ddd-domain-driven-design.md](./03-ddd-domain-driven-design.md) | Modelar el negocio con DDD |
| 4 | [04-microservicios-comunicacion.md](./04-microservicios-comunicacion.md) | Cómo se hablan los servicios entre sí |
| 5 | [05-servicios-azure.md](./05-servicios-azure.md) | Servicios Microsoft Azure explicados |
| 6 | [06-servicios-aws.md](./06-servicios-aws.md) | Servicios AWS explicados |
| 7 | [07-contenedores-docker.md](./07-contenedores-docker.md) | Contenedores, Dockerfile y Docker Compose |
| 8 | [08-kubernetes-orquestacion.md](./08-kubernetes-orquestacion.md) | Kubernetes y orquestación |
| 9 | [09-ci-cd-devops.md](./09-ci-cd-devops.md) | Pipelines y entrega continua |
| 10 | [10-observabilidad.md](./10-observabilidad.md) | Métricas, logs y trazas |
| 11 | [11-resiliencia.md](./11-resiliencia.md) | Qué pasa cuando algo falla |
| 12 | [12-integracion-ia-mcp.md](./12-integracion-ia-mcp.md) | IA y protocolo MCP |
| 13 | [13-sintesis-integracion.md](./13-sintesis-integracion.md) | Mapa final: cómo encaja todo |

**Tiempo orientativo:** dedica entre 1 y 2 horas por capítulo la primera vez. Volver a leer un capítulo con calma es normal.

---

## Rutas según tu interés

| Si quieres enfocarte en… | Lee en este orden |
|---|---|
| **Escribir mejor código y organizar proyectos** | 01 → 02 → 03 → 13 |
| **Backend distribuido** | 02 → 03 → 04 → 10 → 11 → 13 |
| **Cloud y despliegue** | 05 → 06 → 07 → 08 → 09 → 13 |
| **Operar sistemas en producción** | 07 → 08 → 09 → 10 → 11 → 13 |

---

## Recursos gráficos

| Tipo | Ubicación |
|---|---|
| **Imágenes PNG activas** | `assets/images/diagrams/` — visibles en Cursor (sin bloques Mermaid en el MD) |
| Fuentes Mermaid editables | [assets/diagrams/](./assets/diagrams/) |
| Regenerar / activar imágenes | `Source/scripts/docs/Activate-TeoriaDiagramImages.ps1` |
| Complementar PNG + fuente editable | `Source/scripts/docs/Complement-FuenteEditableImages.ps1` |
| Guía de edición | [assets/RECURSOS-GRAFICOS.md](./assets/RECURSOS-GRAFICOS.md) |

> **Visualización:** Cada diagrama usa **imagen incrustada** (`![alt](./assets/images/diagrams/....png)`). Abre la **vista previa Markdown** (`Ctrl+Shift+V`) para ver los diagramas renderizados. La línea *Fuente editable* enlaza solo al `.mermaid`.

---

## Método de estudio (recomendado por el instructor)

1. **Lee con lápiz y papel.** Dibuja el diagrama del capítulo sin mirar.
2. **Explica en voz alta** cada definición como si se la contaras a un compañero junior.
3. **No memorices nombres:** entiende el *problema* que resuelve cada patrón.
4. **Relaciona con lo que ya conoces.** Si has usado Entity Framework, compáralo con Repository.
5. Cierra con el capítulo 13 para ver el panorama completo.

---

## Relación con la práctica

Esta guía es **teoría general**. No sustituye escribir código ni desplegar servicios, pero te da el vocabulario y el criterio para entender *por qué* se toman decisiones en proyectos reales.
