# SPEC — Despliegue Azure (ACA + AKS)

## Objetivo

Desplegar o actualizar ShopDemo en Azure Container Apps y/o AKS siguiendo guías del curso.

## Referencias

- [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](../../../docs/despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../../../docs/despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-AKS.md](../../../docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)

## Criterios de aceptación

- [ ] Imágenes en ACR
- [ ] 4 APIs + MCP (si aplica) con health `/health`
- [ ] Pasos documentados en Portal **y** CLI ejecutados o descritos

## Instrucciones para el agente

Usar command/skill `deploy-azure`. No mezclar instrucciones AWS en el mismo cambio.
