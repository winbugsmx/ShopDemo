# SPEC — Despliegue AWS (ECS + EKS)

## Objetivo

Desplegar ShopDemo en ECS Fargate y/o EKS con ECR.

## Referencias

- [REQUERIMIENTOS-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../../../docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md)
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](../../../docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](../../../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

## Criterios de aceptación

- [ ] Imágenes en ECR
- [ ] Log groups CloudWatch para cada servicio
- [ ] Event Hubs accesible desde VPC (salida HTTPS)

## Instrucciones para el agente

Usar command/skill `deploy-aws`. Separado de Azure.
