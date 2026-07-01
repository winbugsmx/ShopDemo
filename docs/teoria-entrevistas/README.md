# Guía de teoría técnica — Material de estudio

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
| 7 | [07-kubernetes-orquestacion.md](./07-kubernetes-orquestacion.md) | Contenedores y Kubernetes desde cero |
| 8 | [08-ci-cd-devops.md](./08-ci-cd-devops.md) | Pipelines y entrega continua |
| 9 | [09-observabilidad.md](./09-observabilidad.md) | Métricas, logs y trazas |
| 10 | [10-resiliencia.md](./10-resiliencia.md) | Qué pasa cuando algo falla |
| 11 | [11-integracion-ia-mcp.md](./11-integracion-ia-mcp.md) | IA y protocolo MCP |
| 12 | [12-sintesis-integracion.md](./12-sintesis-integracion.md) | Mapa final: cómo encaja todo |

**Tiempo orientativo:** dedica entre 1 y 2 horas por capítulo la primera vez. Volver a leer un capítulo con calma es normal.

---

## Rutas según tu interés

| Si quieres enfocarte en… | Lee en este orden |
|---|---|
| **Escribir mejor código y organizar proyectos** | 01 → 02 → 03 → 12 |
| **Backend distribuido** | 02 → 03 → 04 → 09 → 10 → 12 |
| **Cloud y despliegue** | 05 → 06 → 07 → 08 → 12 |
| **Operar sistemas en producción** | 07 → 08 → 09 → 10 → 12 |

---

## Recursos gráficos

| Tipo | Ubicación |
|---|---|
| Diagramas dentro de cada capítulo | Bloques Mermaid (se ven en GitHub y en editores compatibles) |
| Archivos fuente para editar | [assets/diagrams/](./assets/diagrams/) |
| Imágenes de apoyo | [assets/images/](./assets/images/) |
| Cómo exportar a draw.io | [assets/RECURSOS-GRAFICOS.md](./assets/RECURSOS-GRAFICOS.md) |

---

## Método de estudio (recomendado por el instructor)

1. **Lee con lápiz y papel.** Dibuja el diagrama del capítulo sin mirar.
2. **Explica en voz alta** cada definición como si se la contaras a un compañero junior.
3. **No memorices nombres:** entiende el *problema* que resuelve cada patrón.
4. **Relaciona con lo que ya conoces.** Si has usado Entity Framework, compáralo con Repository.
5. Cierra con el capítulo 12 para ver el panorama completo.

---

## Relación con la práctica

Esta guía es **teoría general**. No sustituye escribir código ni desplegar servicios, pero te da el vocabulario y el criterio para entender *por qué* se toman decisiones en proyectos reales.
