# ShopDemo — Contexto global para agentes (Cursor)

Mapa operativo del repositorio. **Leer esto primero** antes de cambiar código, docs, K8s o CI/CD.

## Proyecto

Laboratorio multicloud .NET 10: **Catalog, Orders, Inventory, Analytics, MCP Gateway**.  
Mensajería: **Azure Event Hubs** (también en AWS). Orquestación local: **Aspire**.  
Release: **Azure** (ACA/AKS) y **AWS** (ECS/EKS) + **Minikube**.

| Respuestas al usuario | Español |
| Comentarios en código | Inglés, mínimos |
| Commits | Solo si el usuario lo pide explícitamente |

## Mapa del repositorio

| Área | Ruta | Notas |
|---|---|---|
| APIs negocio | `Catalog/`, `Orders/`, `Inventory/` | Clean/Hexagonal + CQRS |
| Analytics | `Aspire/ShopDemo.Analytics.Api/` | Consumidor Event Hubs |
| MCP Gateway | `AI/ShopDemo.Mcp.Api/` | Puerto 8005, `/mcp` |
| Shared kernel | `ShopDemo.Shared/` | Eventos, DDD compartido |
| Manifiestos K8s | `k8s/` | Compartidos + `local/` \| `azure/` \| `aws/` |
| Scripts release | `scripts/azure/`, `scripts/aws/` | PowerShell; no hacen build Docker |
| CI/CD | `.github/workflows/` | 4 workflows tras merge a `main` |
| Curso / release | `docs/` | Fuente de verdad pedagógica |
| Specs agente | `spec-driven/specs/` | Leer SPEC antes de implementar |
| Alcance lab | `docs/despliegue/ALCANCE-LAB-RELEASE.md` | Qué es obligatorio vs opcional |

## Arquitectura de despliegue (decisión rápida)

```
¿Dónde release?
├─ Local dev        → Compose / Aspire / dotnet run
├─ K8s sin nube     → Minikube + k8s/local/
├─ Azure serverless → Deploy-AzureShopDemo.ps1 -Mode ACA
├─ Azure K8s        → Deploy-AzureShopDemo.ps1 -Mode AKS + k8s/azure/
├─ AWS serverless   → Deploy-AwsShopDemo.ps1 -Mode ECS
└─ AWS K8s          → Deploy-AwsShopDemo.ps1 -Mode EKS + k8s/aws/
```

**Regla K8s:** recursos compartidos en `k8s/` (namespace, postgres, azurite, `*/service.yaml`, ingress, HPA).  
**Deployments** solo en la carpeta del cloud. **Nunca** aplicar `k8s/aws/` en AKS ni `k8s/azure/` en EKS.

Orden y scripts: [k8s/README.md](k8s/README.md) · `APPLY_INFRA=true bash .github/scripts/apply-k8s-manifests.sh k8s {local|azure|aws}`

## GitHub Actions

| Workflow | Environment | Destino |
|---|---|---|
| `deploy-azure.yml` | `azure` | Container Apps (5 servicios) |
| `deploy-aws.yml` | `aws` | ECS Fargate |
| `deploy-aks.yml` | `azure-aks` | AKS + `k8s/azure/` |
| `deploy-eks.yml` | `aws-eks` | EKS + `k8s/aws/` |

- Disparo: **merge a `main`**, no en PR abierto.
- Infra inicial: scripts PowerShell (una vez).
- Primer run K8s manual: `sync_secrets` + `apply_manifests` (+ `apply_infra` si cluster vacío).
- **No usar `secrets.*` en condiciones `if:`** de workflows — inválido en `workflow_dispatch`.
- Checklist: [.github/SECRETS-CHECKLIST.md](.github/SECRETS-CHECKLIST.md)

## Flujo spec-driven

1. Leer `REQUERIMIENTOS-*.md` (negocio) y `spec-driven/specs/<área>/SPEC.md`.
2. Consultar `ANEXO-ESPECIFICACION-TECNICA-*.md` y `IMPLEMENTACION-*.md` enlazados.
3. Cambio mínimo acotado al SPEC; no refactorizar fuera de alcance.
4. Validar criterios CA-N (negocio) y CA-T (técnico) del módulo.
5. **No mezclar** comandos Azure CLI y AWS CLI en una misma tarea salvo petición explícita.

**Guía documental:** [docs/GUIA-ESTRUCTURA-DOCUMENTACION.md](docs/GUIA-ESTRUCTURA-DOCUMENTACION.md)

## Build y verificación

```powershell
dotnet build ShopDemo.slnx
```

Post-release: `GET /health` por servicio · Postman carpeta **Flujo integrado (E2E)** · [docs/GUIA-ENDPOINTS.md](docs/GUIA-ENDPOINTS.md)

## Secretos — nunca commitear

- `scripts/azure/.env.azure`, `scripts/aws/.env.aws`
- `k8s/secrets.yaml` (generado por scripts)
- Connection strings, PATs, API keys
- `.vs/`, `bin/`, `obj/`

## Sincronización docs ↔ código

Al cambiar estructura K8s, workflows o scripts, actualizar **en el mismo PR**:

| Cambio | Docs a revisar |
|---|---|
| `k8s/**` | `k8s/README.md`, guías AKS/EKS/Minikube, `ALCANCE-LAB-RELEASE.md`, README release |
| `.github/**` | `SECRETS-CHECKLIST.md`, `SETUP-GITHUB*.md`, `.github/README.md` |
| `scripts/**/*.ps1` | `scripts/*/README.md`, guías Script Azure/AWS |
| MCP / Ingress | `docs/integracion-ia/`, `k8s/ingress/` |

Evitar rutas obsoletas: `k8s/catalog/deployment.yaml`, `kubectl apply -f k8s/` genérico, “mismos YAML en todos los clouds”.

## Servicios y puertos

| Servicio | Puerto | Health |
|---|---|---|
| Catalog | 8001 | `/health`, `/alive` |
| Orders | 8002 | `/health`, `/alive` |
| Inventory | 8003 | `/health`, `/alive` |
| Analytics | 8004 | `/health`, `/alive` |
| MCP | 8005 | `/health` |

Consumer groups Event Hubs obligatorios: `analytics-service`, `inventory-service` en hub `shopdemo-events`.

## Post-script frecuente (AKS/EKS)

1. Push imágenes al registry (ACR/ECR).
2. Apply manifiestos (carpeta cloud correcta).
3. Consumer groups Event Hubs.
4. Ingress NGINX + health probe Azure si aplica.
5. Entrada `hosts`: `<IP> shopdemo.local`.
6. Swagger en nube: `ASPNETCORE_ENVIRONMENT=Development` o LB `:8080/swagger`.

## Índice rápido de ayuda

| Necesito… | Documento |
|---|---|
| Elegir ruta release | [ALCANCE-LAB-RELEASE.md](docs/despliegue/ALCANCE-LAB-RELEASE.md) |
| Script Azure | [GUIA-RELEASE-SCRIPT-AZURE.md](docs/despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) |
| Script AWS | [GUIA-RELEASE-SCRIPT-AWS.md](docs/despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) |
| K8s local/AKS/EKS | [GUIA-RELEASE-KUBERNETES.md](docs/despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md) |
| Configurar GitHub | [SETUP-GITHUB-PORTAL.md](.github/SETUP-GITHUB-PORTAL.md) |
| Arquitectura completa | [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) |
| Teoría técnica | [docs/teoria-entrevistas/README.md](docs/teoria-entrevistas/README.md) |
