# Integración de IA — ShopDemo

Material para **alertas, MCP Gateway, Semantic Kernel** en Azure y AWS.

## Integración IA (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-INTEGRACION-IA.md](./REQUERIMIENTOS-INTEGRACION-IA.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-INTEGRACION-IA.md](./HISTORIAS-USUARIO-INTEGRACION-IA.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA.md](./ANEXO-ESPECIFICACION-TECNICA-INTEGRACION-IA.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md](./ANEXO-HISTORIAS-TECNICAS-INTEGRACION-IA.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-INTEGRACION-IA.md](./ANEXO-PEDAGOGIA-INTEGRACION-IA.md) |

## Despliegue MCP (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./REQUERIMIENTOS-DESPLIEGUE-MCP.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-DESPLIEGUE-MCP.md](./HISTORIAS-USUARIO-DESPLIEGUE-MCP.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md](./ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md](./ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-DESPLIEGUE-MCP.md](./ANEXO-PEDAGOGIA-DESPLIEGUE-MCP.md) |

## Implementación

| Tipo | Enlace |
|---|---|
| MCP local | [IMPLEMENTACION-MCP-GATEWAY.md](./IMPLEMENTACION-MCP-GATEWAY.md) |
| MCP Azure | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |
| MCP AWS | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |
| IA Azure | [azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md](./azure/IMPLEMENTACION-INTEGRACION-IA-AZURE.md) |
| IA AWS | [aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md](./aws/IMPLEMENTACION-INTEGRACION-IA-AWS.md) |
| Teoría lab | [TEORIA-INTEGRACION-IA.md](./TEORIA-INTEGRACION-IA.md) |
| Tópico 12 (teoría general) | [12-integracion-ia-mcp.md](../../Documentación de Estudio del Curso/12-integracion-ia-mcp.md) |
| Código MCP | [ANEXO-CODIGO-MCP.md](./ANEXO-CODIGO-MCP.md) |

Índice Tópicos de Estudio: [Documentación de Estudio del Curso/README.md](../../Documentación de Estudio del Curso/README.md)

## Código

| Componente | Ruta | Puerto |
|---|---|---|
| **MCP Gateway** | [Source/AI/ShopDemo.Mcp.Api](../../Source/AI/ShopDemo.Mcp.Api/) | 8005 (`/mcp`) |

**Tools:** `CreateProduct`, `GetProductStock`, `ListAnalyticsEvents`, `GetShopDemoStatus`

## Relación

- [observabilidad/](../observabilidad/) — prerequisito logs
- [despliegue/](../despliegue/) — prerequisito APIs en nube
- [GUIA-ESTRUCTURA-DOCUMENTACION.md](../GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Orden de lectura

1. `REQUERIMIENTOS-INTEGRACION-IA.md` → contexto negocio
2. `REQUERIMIENTOS-DESPLIEGUE-MCP.md` → despliegue gateway
3. Anexos técnicos → implementación
4. `ANEXO-PEDAGOGIA-*.md` → si eres alumno del curso
