# Recursos gráficos — Material de estudio

Diagramas de apoyo para los capítulos 01–12. Cada archivo `.mermaid` en `assets/diagrams/` es **editable** (draw.io MCP, diagrams.net o el editor del IDE).

---

## Capítulo 01 — Patrones de diseño

| Archivo | Patrón / tema |
|---|---|
| `01-factory-method.mermaid` | Factory Method |
| `01-abstract-factory.mermaid` | Abstract Factory |
| `01-builder.mermaid` | Builder |
| `01-composite.mermaid` | Composite |
| `01-state.mermaid` | State |
| `01-adapter.mermaid` | Adapter |
| `01-facade.mermaid` | Facade |
| `01-decorator.mermaid` | Decorator |
| `01-strategy.mermaid` | Strategy |
| `01-observer.mermaid` | Observer |
| `01-command.mermaid` | Command |
| `01-cqrs-mediator.mermaid` | Mediator / flujo command |
| `01-cqrs-split.mermaid` | CQRS lectura vs escritura |
| `01-repository.mermaid` | Repository |
| `01-unit-of-work.mermaid` | Unit of Work |
| `01-outbox.mermaid` | Outbox pattern |
| `01-saga-overview.mermaid` | Saga (introducción) |

---

## Capítulo 02 — Arquitecturas

| Archivo | Tema |
|---|---|
| `02-monolito-modular.mermaid` | Monolito modular |
| `02-microservicios.mermaid` | Microservicios y BD por servicio |
| `02-layered.mermaid` | Arquitectura en capas |
| `02-clean-architecture.mermaid` | Clean Architecture |
| `02-hexagonal.mermaid` | Hexagonal (ports & adapters) |
| `02-event-driven.mermaid` | Event-driven |

---

## Capítulo 03 — DDD

| Archivo | Tema |
|---|---|
| `03-ddd-levels.mermaid` | Estratégico vs táctico |
| `03-bounded-contexts.mermaid` | Bounded contexts |
| `03-context-map.mermaid` | Context map |
| `03-aggregate.mermaid` | Aggregate root |

---

## Capítulo 04 — Microservicios

| Archivo | Tema |
|---|---|
| `04-sync-vs-async.mermaid` | Síncrono vs asíncrono |
| `04-sync-http.mermaid` | HTTP request/response |
| `04-saga-steps.mermaid` | Pasos de saga |
| `04-saga-orchestration.mermaid` | Orquestación |

---

## Capítulos 05–08 — Cloud, K8s, CI/CD

| Archivo | Capítulo |
|---|---|
| `05-azure-stack.mermaid` | 05 Azure |
| `06-aws-stack.mermaid` | 06 AWS |
| `07-k8s-architecture.mermaid` | 07 Kubernetes |
| `08-cicd-pipeline.mermaid` | 08 CI/CD |

*(Los capítulos 05–08 incluyen diagramas adicionales embebidos en el markdown.)*

---

## Capítulos 09–12 — Observabilidad, resiliencia, IA, síntesis

| Archivo | Capítulo |
|---|---|
| `09-distributed-tracing.mermaid` | 09 Trazas |
| `09-observability-correlation.mermaid` | 09 Correlación de señales |
| `09-sli-slo-budget.mermaid` | 09 SLI/SLO/error budget |
| `10-circuit-breaker.mermaid` | 10 Circuit breaker |
| `10-failure-cascade.mermaid` | 10 Cascada de fallos |
| `10-resilience-patterns.mermaid` | 10 Patrones de resiliencia |
| `11-mcp-architecture.mermaid` | 11 MCP |
| `11-rag-flow.mermaid` | 11 Flujo RAG |
| `11-agent-loop.mermaid` | 11 Bucle de agente |
| `12-chapter-map.mermaid` | 12 Mapa de capítulos |
| `12-journey-production.mermaid` | 12 Del código a producción |
| `12-decision-tree.mermaid` | 12 Árbol de decisiones arquitectónicas |
| `12-order-system-flow.mermaid` | 12 Flujo integrado sistema de pedidos |

---

## Visualización en Cursor / VS Code

| Problema | Solución |
|---|---|
| Solo ves código `flowchart TB...` en gris | Los capítulos **no usan bloques Mermaid** en el markdown |
| Ver diagramas sin configurar nada | Abre **vista previa Markdown** (`Ctrl+Shift+V`) en cada capítulo |
| Editar un diagrama | Abre el `.mermaid` enlazado bajo *Fuente editable* |
| Regenerar PNG tras editar | `scripts/docs/Export-TeoriaDiagrams.ps1` y luego `Activate-TeoriaDiagramImages.ps1` |

### Formato en cada capítulo

```markdown
![Diagrama: 02-monolito-modular](./assets/images/diagrams/02-monolito-modular.png)

> *Fuente editable (Mermaid):* [02-monolito-modular.mermaid](./assets/diagrams/02-monolito-modular.mermaid)
```

- **Imagen incrustada:** sintaxis Markdown `![alt](ruta.png)` — visible en la vista previa del capítulo.
- **Fuente Mermaid:** enlace solo al `.mermaid` para editar y reexportar (la PNG ya está arriba).

Carpeta PNG activa en documentación: **`assets/images/diagrams/`** (servida en los capítulos).

Carpeta fuente de exportación: `assets/diagrams/png/` (generada por el script).

```powershell
cd I:\Curso\ShopDemo\scripts\docs
npm install                              # primera vez
.\Export-TeoriaDiagrams.ps1              # .mermaid -> PNG
.\Activate-TeoriaDiagramImages.ps1       # copia PNG, convierte refs, complementa Fuente editable
.\Embed-TeoriaDiagramImages.ps1          # asegura sintaxis ![alt](png) incrustada
```

Visor de ayuda: [visor-diagramas.html](../visor-diagramas.html)

---

## Imágenes PNG (infografías)

| Archivo | Capítulos |
|---|---|
| `clean-vs-hexagonal.png` | 02 |
| `azure-vs-aws-servicios.png` | 05, 06 |
| `pilares-observabilidad.png` | 09 |

Ubicación: [assets/images/](./images/)

---

## Cómo editar en draw.io (Cursor MCP)

1. Abre el archivo `.mermaid` o copia el bloque del capítulo.
2. Pide al agente: *“Abre en draw.io el diagrama de …”*
3. Exporta PNG si necesitas versión estática en presentaciones.

Ver también: [app.diagrams.net](https://app.diagrams.net) → **Arrange → Insert → Advanced → Mermaid**.
