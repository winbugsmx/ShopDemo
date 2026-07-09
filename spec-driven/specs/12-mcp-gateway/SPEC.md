# SPEC — MCP Gateway (ShopDemo.Mcp.Api)

## Objetivo

Desplegar y consumir el MCP Server que expone tools sobre Catalog, Inventory y Analytics.

## Documentación (3 capas)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/HISTORIAS-USUARIO-DESPLIEGUE-MCP.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-MCP.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/ANEXO-PEDAGOGIA-DESPLIEGUE-MCP.md) |
| Implementación | [IMPLEMENTACION-MCP-GATEWAY.md](../../../docs/integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md) |
| Deploy Azure | [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |
| Deploy AWS | [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |
| Código | [ANEXO-CODIGO-MCP.md](../../../docs/integracion-ia/ANEXO-CODIGO-MCP.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- Código: `AI/ShopDemo.Mcp.Api/`
- Endpoint `/mcp`, tools HTTP hacia Catalog, Inventory, Analytics
- Despliegue: ACA, AKS, ECS, EKS o `k8s/*/mcp/`

## Variables MCP

| Entorno | `ShopDemo__CatalogApiBaseUrl` ejemplo |
|---|---|
| Local | `http://localhost:8001` |
| K8s cluster | `http://shopdemo-catalog:8080` |
| ACA | `https://<fqdn-catalog>` |

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Agente externo puede operar la tienda vía tools MCP sin conocer cada API por separado
- [ ] Estado de APIs reportado de forma comprensible (`GetShopDemoStatus`)

### Técnico (CA-T)

- [ ] `GET /health` → 200
- [ ] Endpoint `/mcp` accesible al agente
- [ ] `GetShopDemoStatus` reporta APIs alcanzables
- [ ] Deployment en `k8s/local/`, `k8s/azure/` o `k8s/aws/` + `k8s/mcp/service.yaml` si K8s

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-DESPLIEGUE-MCP** (negocio).
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-MCP** para URLs y despliegue.
3. Ajustar `ShopDemo__*ApiBaseUrl` según entorno (tabla arriba).
4. Validar CA-N y CA-T al finalizar.
