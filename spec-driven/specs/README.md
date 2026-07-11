# Especificaciones ShopDemo

Cada carpeta define **qué** debe cumplir el agente antes y durante la implementación.

## Flujo spec-driven

```mermaid
flowchart LR
    N[REQUERIMIENTOS negocio] --> S[SPEC.md]
    S --> T[ANEXO-ESPECIFICACION-TECNICA]
    T --> I[Implementación]
    I --> V[CA-N + CA-T]
```

**Guía de capas:** [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../Documentación_Del_Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md)

Por módulo: `REQUERIMIENTOS` + `HISTORIAS-USUARIO` (negocio) → `ANEXO-ESPECIFICACION-TECNICA` + `ANEXO-HISTORIAS-TECNICAS` (técnico) → `ANEXO-PEDAGOGIA` (curso).

## Índice de specs

Cada `SPEC.md` enlaza la documentación en **3 capas** (negocio → técnica → pedagogía).

| Carpeta | SPEC | Requerimientos (negocio) |
|---|---|---|
| [00-vision](./00-vision/) | [SPEC.md](./00-vision/SPEC.md) | [RETO-TECNICO](../../Documentación_Del_Proyecto/RETO-TECNICO-SHOPDEMO.md) |
| [01-catalog](./01-catalog/) | [SPEC.md](./01-catalog/SPEC.md) | [REQUERIMIENTOS-CATALOG](../../Documentación_Del_Proyecto/catalog/REQUERIMIENTOS-CATALOG.md) |
| [02-orders](./02-orders/) | [SPEC.md](./02-orders/SPEC.md) | [REQUERIMIENTOS-ORDERS](../../Documentación_Del_Proyecto/orders/REQUERIMIENTOS-ORDERS.md) |
| [03-inventory](./03-inventory/) | [SPEC.md](./03-inventory/SPEC.md) | [REQUERIMIENTOS-INVENTORY](../../Documentación_Del_Proyecto/inventory/REQUERIMIENTOS-INVENTORY.md) |
| [04-analytics-aspire](./04-analytics-aspire/) | [SPEC.md](./04-analytics-aspire/SPEC.md) | [REQUERIMIENTOS-ANALYTICS](../../Documentación_Del_Proyecto/analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) |
| [05-event-hubs](./05-event-hubs/) | [SPEC.md](./05-event-hubs/SPEC.md) | [INTEGRACION-EVENT-HUBS](../../Documentación_Del_Proyecto/INTEGRACION-AZURE-EVENT-HUBS.md) |
| [06-deploy-azure](./06-deploy-azure/) | [SPEC.md](./06-deploy-azure/SPEC.md) | [REQUERIMIENTOS-AZURE](../../Documentación_Del_Proyecto/despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) |
| [07-deploy-aws](./07-deploy-aws/) | [SPEC.md](./07-deploy-aws/SPEC.md) | [REQUERIMIENTOS-AWS](../../Documentación_Del_Proyecto/despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) |
| [08-kubernetes](./08-kubernetes/) | [SPEC.md](./08-kubernetes/SPEC.md) | [REQUERIMIENTOS-K8S](../../Documentación_Del_Proyecto/despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md) |
| [09-observabilidad](./09-observabilidad/) | [SPEC.md](./09-observabilidad/SPEC.md) | [REQUERIMIENTOS-OBS](../../Documentación_Del_Proyecto/observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) |
| [10-resiliencia](./10-resiliencia/) | [SPEC.md](./10-resiliencia/SPEC.md) | [REQUERIMIENTOS-RES](../../Documentación_Del_Proyecto/resiliencia/REQUERIMIENTOS-RESILIENCIA.md) |
| [11-integracion-ia](./11-integracion-ia/) | [SPEC.md](./11-integracion-ia/SPEC.md) | [REQUERIMIENTOS-IA](../../Documentación_Del_Proyecto/integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) |
| [12-mcp-gateway](./12-mcp-gateway/) | [SPEC.md](./12-mcp-gateway/SPEC.md) | [REQUERIMIENTOS-MCP](../../Documentación_Del_Proyecto/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) |

## Tópicos de Estudio (teoría general)

Cada spec del lab se complementa con tópicos en [Documentación_De_Estudio_Del_Curso/README.md](../../Documentación_De_Estudio_Del_Curso/README.md):

| Spec | Tópicos recomendados |
|---|---|
| 01–03 catalog/orders/inventory | [01](../../Documentación_De_Estudio_Del_Curso/01-patrones-diseno.md) · [02](../../Documentación_De_Estudio_Del_Curso/02-arquitecturas-software.md) · [03](../../Documentación_De_Estudio_Del_Curso/03-ddd-domain-driven-design.md) |
| 04 analytics / 05 event-hubs | [04](../../Documentación_De_Estudio_Del_Curso/04-microservicios-comunicacion.md) |
| 06 deploy-azure | [05](../../Documentación_De_Estudio_Del_Curso/05-servicios-azure.md) · [07](../../Documentación_De_Estudio_Del_Curso/07-contenedores-docker.md) |
| 07 deploy-aws | [06](../../Documentación_De_Estudio_Del_Curso/06-servicios-aws.md) · [07](../../Documentación_De_Estudio_Del_Curso/07-contenedores-docker.md) |
| 08 kubernetes | [07](../../Documentación_De_Estudio_Del_Curso/07-contenedores-docker.md) · [08](../../Documentación_De_Estudio_Del_Curso/08-kubernetes-orquestacion.md) |
| 09 observabilidad | [10](../../Documentación_De_Estudio_Del_Curso/10-observabilidad.md) |
| 10 resiliencia | [11](../../Documentación_De_Estudio_Del_Curso/11-resiliencia.md) |
| 11–12 IA / MCP | [12](../../Documentación_De_Estudio_Del_Curso/12-integracion-ia-mcp.md) |

## Uso con el agente

Prompt recomendado:

```
Implementa según spec-driven/specs/<carpeta>/SPEC.md.

Orden de lectura:
1. REQUERIMIENTOS + HISTORIAS-USUARIO (negocio)
2. ANEXO-ESPECIFICACION-TECNICA + ANEXO-HISTORIAS-TECNICAS
3. IMPLEMENTACION (si aplica)

Valida CA-N (negocio) y CA-T (técnico) al finalizar.
```
