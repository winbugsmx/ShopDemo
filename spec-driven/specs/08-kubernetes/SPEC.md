# SPEC — Kubernetes (Minikube, manifiestos k8s/)

## Objetivo

Aplicar o modificar manifiestos en `k8s/` para local, AKS y EKS.

## Documentación (3 capas)

### Kubernetes local (Minikube)

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-KUBERNETES.md](../../../Documentación_Del_Proyecto/despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-KUBERNETES.md](../../../Documentación_Del_Proyecto/despliegue/kubernetes/HISTORIAS-USUARIO-KUBERNETES.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md](../../../Documentación_Del_Proyecto/despliegue/kubernetes/ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md](../../../Documentación_Del_Proyecto/despliegue/kubernetes/ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-KUBERNETES.md](../../../Documentación_Del_Proyecto/despliegue/kubernetes/ANEXO-PEDAGOGIA-KUBERNETES.md) |
| Implementación | [IMPLEMENTACION-KUBERNETES-LOCAL.md](../../../Documentación_Del_Proyecto/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) |

### AKS / EKS (despliegue en cluster nube)

| Entorno | Anexo técnico |
|---|---|
| AKS | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md](../../../Documentación_Del_Proyecto/despliegue/aks/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-AKS.md) |
| EKS | [ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-EKS.md](../../../Documentación_Del_Proyecto/despliegue/eks/ANEXO-ESPECIFICACION-TECNICA-DESPLIEGUE-EKS.md) |

| Recurso | Documento |
|---|---|
| Manifiestos | [k8s/README.md](../../../k8s/README.md) |
| Guía | [GUIA-ESTRUCTURA-DOCUMENTACION.md](../../../Documentación_Del_Proyecto/GUIA-ESTRUCTURA-DOCUMENTACION.md) |

## Alcance (agente)

- `k8s/local/`, `k8s/azure/`, `k8s/aws/` — **nunca mezclar carpetas entre clouds**
- Orden: namespace → secrets → postgres → azurite → APIs → mcp → ingress → HPA

## Criterios de aceptación

### Negocio (CA-N)

- [ ] Flujo E2E funciona en cluster K8s (crear producto → pedido → confirmar)

### Técnico (CA-T)

- [ ] Orden de apply respetado
- [ ] Probes HTTP `/health` en Deployments
- [ ] `kubectl get pods -n shopdemo` todos Running
- [ ] HPA configurado donde aplica

## Instrucciones para el agente

1. Leer **REQUERIMIENTOS-KUBERNETES** (negocio).
2. Consultar **ANEXO-ESPECIFICACION-TECNICA-KUBERNETES** y [k8s/README.md](../../../k8s/README.md).
3. Aplicar solo manifiestos del cloud objetivo (`local`, `azure` o `aws`).
4. Validar CA-N y CA-T al finalizar.
