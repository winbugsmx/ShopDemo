# Requerimientos — Despliegue del MCP Gateway (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Componente:** `AI/ShopDemo.Mcp.Api` · **Puerto:** 8005 (local) / 8080 (contenedor)  
**Versión:** 1.0

**Historias de usuario:** [HISTORIAS-USUARIO-DESPLIEGUE-MCP.md](./HISTORIAS-USUARIO-DESPLIEGUE-MCP.md)

---

## 1. Propósito

Justificar el despliegue del **MCP Gateway** como quinto contenedor de ShopDemo en **Azure (ACA + AKS)** y **AWS (ECS + EKS)**, alineado con el resto de microservicios: misma imagen Docker, health checks, Ingress y CI/CD.

El gateway no sustituye Catalog/Orders/Inventory/Analytics; expone **tools MCP** (`/mcp`) para agentes IA delegando en esas APIs por HTTP.

---

## 2. Problema que resuelve

| Situación | Necesidad |
|---|---|
| MCP solo en `dotnet run` local | Agentes no pueden consumir tools en nube |
| Sin manifiestos `k8s/mcp/` | AKS/EKS/Minikube no despliegan el gateway |
| Sin entrada en CI/CD | La imagen no se publica en ACR/ECR automáticamente |
| Sin ruta Ingress `/mcp` | No hay URL única tras el balanceador |

---

## 3. Objetivos

| ID | Objetivo |
|---|---|
| OBJ-MCP-01 | Empaquetar `ShopDemo.Mcp.Api` en imagen Docker |
| OBJ-MCP-02 | Desplegar en **Azure Container Apps** con health probe y env vars de APIs |
| OBJ-MCP-03 | Desplegar en **AKS** con manifiestos `k8s/mcp/` e Ingress `/mcp` |
| OBJ-MCP-04 | Desplegar en **ECS Fargate** con ALB y log group CloudWatch |
| OBJ-MCP-05 | Desplegar en **EKS** reutilizando manifiestos K8s |
| OBJ-MCP-06 | Incluir MCP en workflows `deploy-azure.yml` y `deploy-aws.yml` |
| OBJ-MCP-07 | Documentar pasos **Portal/Consola** y **CLI** en cada plataforma |

---

## 4. Alcance incluido

- `k8s/mcp/deployment.yaml` y `service.yaml`
- Ruta `/mcp` en `k8s/ingress/ingress.yaml`
- Variables `ShopDemo__*ApiBaseUrl` por entorno
- Health check HTTP `GET /health`
- Build context desde raíz del repo (`AI/ShopDemo.Mcp.Api/Dockerfile`)
- Prerequisito: las 4 APIs de negocio ya desplegadas y alcanzables

## 5. No incluido en el lab

| Tema | Motivo |
|---|---|
| Autenticación OAuth en MCP | Lab básico; red/Ingress controlan acceso |
| AppHost Aspire orquestando MCP | MCP es servicio independiente en nube |
| mTLS entre MCP y APIs internas | Complejidad enterprise |

---

## 6. Criterios de aceptación

| # | Criterio |
|---|---|
| CA-MCP-01 | `curl .../health` → 200 en ACA, ECS, AKS y EKS |
| CA-MCP-02 | Agente IA lista tools contra URL `/mcp` |
| CA-MCP-03 | `GetShopDemoStatus` reporta APIs OK |
| CA-MCP-04 | `kubectl get pods -n shopdemo -l app=shopdemo-mcp` → Running |
| CA-MCP-05 | Workflow GitHub actualiza imagen en ACR/ECR |

---

## 7. Dependencias

- [IMPLEMENTACION-DESPLIEGUE-AZURE.md](../despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) — APIs en ACA
- [IMPLEMENTACION-DESPLIEGUE-AKS.md](../despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) — cluster AKS
- [IMPLEMENTACION-DESPLIEGUE-AWS.md](../despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) — ECS
- [IMPLEMENTACION-DESPLIEGUE-EKS.md](../despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) — EKS
- [TEORIA-INTEGRACION-IA.md](./TEORIA-INTEGRACION-IA.md) — concepto MCP

---

## Referencias

- [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md)
- [IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md](./IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)
- [AI/ShopDemo.Mcp.Api](../../AI/ShopDemo.Mcp.Api/)
