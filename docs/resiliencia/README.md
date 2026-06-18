# Resiliencia de servicios — ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

Material del curso para **patrones de resiliencia nativos de nube**, redundancia y comunicación entre microservicios en **Azure** y **AWS**.

## Documentos

| Tipo | Enlace |
|---|---|
| **Teoría** | [TEORIA-RESILIENCIA.md](./TEORIA-RESILIENCIA.md) |
| **Requerimientos** | [REQUERIMIENTOS-RESILIENCIA.md](./REQUERIMIENTOS-RESILIENCIA.md) |
| **Implementación Azure** (ACA + AKS) | [azure/IMPLEMENTACION-RESILIENCIA-AZURE.md](./azure/IMPLEMENTACION-RESILIENCIA-AZURE.md) |
| **Implementación AWS** (ECS + EKS) | [aws/IMPLEMENTACION-RESILIENCIA-AWS.md](./aws/IMPLEMENTACION-RESILIENCIA-AWS.md) |

## Estado actual en el código

| Patrón | Implementación ShopDemo |
|---|---|
| Health checks HTTP | `/health`, `/alive` en las 4 APIs |
| Comunicación síncrona | Orders → Inventory (`InventoryHttpClient`) |
| Comunicación asíncrona | Azure Event Hubs (desacoplamiento) |
| Resiliencia HTTP (retry/circuit breaker) | `AddStandardResilienceHandler` solo en **ServiceDefaults** (Analytics) |
| Réplicas / escalado | HPA Catalog en `k8s/catalog/hpa.yaml` |
| Tolerancia a fallos de proceso | Probes K8s + reinicio de contenedor |

## Plataformas cubiertas

| Azure | AWS |
|---|---|
| Container Apps | ECS Fargate |
| AKS | EKS |

**Nota:** La predicción de fallos con IA queda **fuera de alcance** en esta etapa (ver requerimientos).
