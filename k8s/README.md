# Manifiestos Kubernetes — ShopDemo

Despliegue de **4 APIs + MCP + PostgreSQL (StatefulSet) + Azurite + Ingress NGINX** en el namespace `shopdemo`.

## Estructura

```
k8s/
├── namespace.yaml
├── secrets.example.yaml      → copiar a secrets.yaml (no commitear)
├── postgres/                 → StatefulSet + Service headless
├── azurite/                  → Checkpoints Event Hubs
├── catalog/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml              → HPA demo (Catalog)
├── orders/
├── inventory/
├── analytics/
├── mcp/                      → MCP Gateway (agentes IA)
└── ingress/                  → NGINX Ingress (shopdemo.local)
```

## Orden de aplicación

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/azurite/
# Esperar postgres ready
kubectl apply -f k8s/catalog/
kubectl apply -f k8s/inventory/
kubectl apply -f k8s/orders/
kubectl apply -f k8s/analytics/
kubectl apply -f k8s/mcp/
kubectl apply -f k8s/catalog/hpa.yaml
kubectl apply -f k8s/ingress/
```

## Documentación

| Entorno | Guía |
|---|---|
| Minikube (local) | [docs/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md](../docs/despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) |
| Azure AKS | [docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md](../docs/despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |
| Amazon EKS | [docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md](../docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |
| MCP Gateway | [docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](../docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) |
