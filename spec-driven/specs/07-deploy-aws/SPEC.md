# SPEC — Despliegue AWS (ECS + EKS)

## Objetivo

Desplegar ShopDemo en ECS Fargate y/o EKS con ECR.

## Documentación (3 capas)

### AWS ECS

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/HISTORIAS-USUARIO-DESPLIEGUE-AWS.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/ANEXO-HISTORIAS-TECNICAS-DESPLIEGUE-AWS.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/ANEXO-PEDAGOGIA-DESPLIEGUE-AWS.md) |
| Implementación | [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) |
| Task definitions | [ANEXO-TASK-DEFINITIONS-ECS.md](../../../docs/despliegue/aws/ANEXO-TASK-DEFINITIONS-ECS.md) |

### Amazon EKS (si aplica)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-DESPLIEGUE-EKS.md](../../../docs/despliegue/eks/REQUERIMIENTOS-DESPLIEGUE-EKS.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-EKS.md](../../../docs/despliegue/eks/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-EKS.md) |
| Implementación | [IMPLEMENTACION-DESPLIEGUE-EKS.md](../../../docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |

### MCP en AWS

| Documento |
|---|
| [REQUERIMIENTOS-DESPLIEGUE-MCP.md](../../../docs/integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) |
| [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |

Guía: [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Alcance (agente)

- ECR, ECS Fargate, ALB, VPC, SSM secrets
- Opcional: EKS + `k8s/aws/`
- Event Hubs accesible vía HTTPS desde VPC
- Scripts: `scripts/aws/`

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Flujo E2E en AWS: APIs accesibles y pedido confirmable

### Técnico (CA-T)

- [ ] Imágenes en ECR
- [ ] Log groups CloudWatch por servicio
- [ ] Event Hubs accesible desde VPC (salida HTTPS)
- [ ] Secretos en SSM/Parameter Store, no en git

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-DESPLIEGUE-AWS** (negocio) primero.
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AWS**.
3. Usar command/skill `deploy-aws`. **Separado de Azure**.
4. Validar CA-N y CA-T al finalizar.
