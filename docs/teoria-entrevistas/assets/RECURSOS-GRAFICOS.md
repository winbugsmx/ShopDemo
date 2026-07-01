# Recursos gráficos — Teoría para entrevistas

## Diagramas Mermaid (fuente en repo)

Cada archivo en `assets/diagrams/*.mermaid` es la **fuente editable** del diagrama.

| Archivo | Usado en |
|---|---|
| `01-bounded-contexts.mermaid` | [03-ddd-y-bounded-contexts.md](../03-ddd-y-bounded-contexts.md) |
| `02-clean-architecture.mermaid` | [02-arquitecturas-software.md](../02-arquitecturas-software.md) |
| `03-hexagonal.mermaid` | [02-arquitecturas-software.md](../02-arquitecturas-software.md) |
| `04-secuencia-e2e.mermaid` | [04-comunicacion-microservicios.md](../04-comunicacion-microservicios.md) |
| `05-azure-release.mermaid` | [05-servicios-azure.md](../05-servicios-azure.md) |
| `06-aws-release.mermaid` | [06-servicios-aws.md](../06-servicios-aws.md) |
| `07-k8s-estructura.mermaid` | [07-kubernetes-cloud-native.md](../07-kubernetes-cloud-native.md) |
| `08-cicd.mermaid` | [08-ci-cd-devops.md](../08-ci-cd-devops.md) |
| `09-observabilidad-resiliencia.mermaid` | [11-observabilidad-resiliencia.md](../11-observabilidad-resiliencia.md) |
| `10-incidente-investigacion.mermaid` | [11-observabilidad-resiliencia.md](../11-observabilidad-resiliencia.md) |

## Abrir en draw.io (Cursor MCP)

1. Copia el contenido de un `.mermaid`.
2. En Cursor, pide al agente: *“Abre en draw.io el diagrama X”* (MCP `drawio`).
3. O pega el Mermaid en [app.diagrams.net](https://app.diagrams.net) → **Arrange → Insert → Advanced → Mermaid**.

Exporta desde draw.io como `.drawio` o PNG y guárdalo en `assets/images/` si quieres versionar imágenes estáticas.

## Imágenes generadas (MCP mcp-image)

Carpeta prevista: `assets/images/`. Genera infografías con el agente:

```
Genera imagen educativa 16:9 para [tema] y guárdala en docs/teoria-entrevistas/assets/images/
```

Requiere `GEMINI_API_KEY` válida en `~/.cursor/mcp.json`. Si hay error 429 (cuota), reintenta más tarde o usa solo Mermaid/draw.io.
