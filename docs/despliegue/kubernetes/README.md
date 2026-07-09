# Despliegue en Kubernetes — ShopDemo

Material para desplegar ShopDemo en **Kubernetes**: desarrollo local (Minikube) y extensión a AKS/EKS.

**Guía de elección:** [GUIA-RELEASE-KUBERNETES.md](./GUIA-RELEASE-KUBERNETES.md) · **Alcance:** [ALCANCE-LAB-RELEASE.md](../ALCANCE-LAB-RELEASE.md)

## Documentación (3 capas) — Kubernetes local

| Capa | Documento |
|---|---|
| **A — Negocio** | [REQUERIMIENTOS-KUBERNETES.md](./REQUERIMIENTOS-KUBERNETES.md) |
| **A — Negocio** | [HISTORIAS-USUARIO-KUBERNETES.md](./HISTORIAS-USUARIO-KUBERNETES.md) |
| **B — Técnica** | [ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md](./ANEXO-ESPECIFICACION-TECNICA-KUBERNETES.md) |
| **B — Técnica** | [ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md](./ANEXO-HISTORIAS-TECNICAS-KUBERNETES.md) |
| **C — Pedagogía** | [ANEXO-PEDAGOGIA-KUBERNETES.md](./ANEXO-PEDAGOGIA-KUBERNETES.md) |

## Implementación y teoría

| Tipo | Enlace |
|---|---|
| Paso a paso local | [IMPLEMENTACION-KUBERNETES-LOCAL.md](./IMPLEMENTACION-KUBERNETES-LOCAL.md) |
| Teoría operaciones | [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md) |
| Manifiestos | [k8s/README.md](../../../k8s/README.md) |

## Tópicos de Estudio relacionados

| # | Tópico | Enlace |
|---|---|---|
| 07 | Contenedores y Docker | [07-contenedores-docker.md](../../teoria-entrevistas/07-contenedores-docker.md) |
| 08 | Kubernetes | [08-kubernetes-orquestacion.md](../../teoria-entrevistas/08-kubernetes-orquestacion.md) |

Teoría lab: [TEORIA-KUBERNETES-OPERACIONES.md](./TEORIA-KUBERNETES-OPERACIONES.md) · Índice: [teoria-entrevistas/README.md](../../teoria-entrevistas/README.md)

## Nube (misma estructura 3 capas)

| Entorno | Carpeta |
|---|---|
| **Azure AKS** | [despliegue/aks/](../aks/) |
| **Amazon EKS** | [despliegue/eks/](../eks/) |

## Scripts

| Plataforma | Script |
|---|---|
| Azure | [Deploy-AzureShopDemo.ps1](../../../scripts/azure/Deploy-AzureShopDemo.ps1) `-Mode AKS` |
| AWS | [Deploy-AwsShopDemo.ps1](../../../scripts/aws/Deploy-AwsShopDemo.ps1) `-Mode EKS` |
