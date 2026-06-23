# SPEC — Kubernetes (Minikube, manifiestos k8s/)

## Objetivo

Aplicar o modificar manifiestos en `k8s/` para local, AKS y EKS.

## Referencias

- [REQUERIMIENTOS-KUBERNETES.md](../../../docs/despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md)
- [IMPLEMENTACION-KUBERNETES-LOCAL.md](../../../docs/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md)
- [k8s/README.md](../../../k8s/README.md)

## Criterios de aceptación

- [ ] Orden: namespace → secrets → postgres → azurite → APIs → mcp → ingress
- [ ] Probes HTTP `/health` en Deployments
- [ ] `kubectl get pods -n shopdemo` todos Running
