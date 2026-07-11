# SPEC — Despliegue Azure (ACA + AKS)

## Objetivo

Desplegar o actualizar ShopDemo en Azure Container Apps y/o AKS siguiendo la documentación del curso.

## Documentación (3 capas)

### Azure Container Apps (ACA)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](../../../Documentación del Proyecto/despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md](../../../Documentación del Proyecto/despliegue/azure/HISTORIAS-USUARIO-DESPLIEGUE-AZURE.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md](../../../Documentación del Proyecto/despliegue/azure/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md](../../../Documentación del Proyecto/despliegue/azure/ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AZURE.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-DESPLIEGUE-AZURE.md](../../../Documentación del Proyecto/despliegue/azure/ANEXO-PEDAGOGIA-DESPLIEGUE-AZURE.md) |
| Implementación | [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../../../Documentación del Proyecto/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) |

### Azure AKS (si aplica)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-DESPLIEGUE-AKS.md](../../../Documentación del Proyecto/despliegue/aks/REQUERIMIENTOS-DESPLIEGUE-AKS.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md](../../../Documentación del Proyecto/despliegue/aks/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md) |
| Implementación | [IMPLEMENTACION-DESPLIEGUE-AKS.md](../../../Documentación del Proyecto/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |

### MCP en Azure

| Documento |
|---|
| [REQUERIMIENTOS-DESPLIEGUE-MCP.md](../../../Documentación del Proyecto/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) |
| [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../../../Documentación del Proyecto/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación del Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- ACR, Container Apps, PostgreSQL ACI, Event Hubs, Storage checkpoints
- Opcional: AKS + `k8s/azure/`
- Scripts: `Source/scripts/azure/`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Flujo E2E en nube: crear producto → confirmar pedido sin error (CA-AZ-03, CA-AZ-04)
- [ ] La tienda responde vía URLs públicas de Source/Catalog/Orders

### Técnico (CA-T)

- [ ] Imágenes en ACR (5 repos si incluye MCP)
- [ ] 4 APIs + MCP con health `/health`
- [ ] Secretos en ACA, no en git
- [ ] Pasos Portal **y** CLI documentados o ejecutados

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-DESPLIEGUE-AZURE** (negocio) primero.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AZURE** para matrices y RNF.
3. Usar command/skill `deploy-azure`. **No mezclar** instrucciones AWS.
4. Validar CA-N y CA-T al finalizar.
