# Guía de desarrollo — Integraciones paso a paso (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |

**Objetivo:** Que el alumno **no se quede sin código** al seguir el curso. Cada etapa indica qué archivos crear o copiar, para qué sirven y dónde está el **código completo** listo para integrar.

---

## Cómo usar esta guía

### Dos formas de trabajar

| Modo | Cuándo | Qué haces |
|---|---|---|
| **A — Repositorio de referencia** | Ya clonaste ShopDemo completo | Sigues los pasos para **validar** etapa por etapa (`dotnet build`, Postman, Docker) |
| **B — Construcción guiada** | Empiezas un proyecto vacío o por capas | En cada paso **copias el código** del anexo o del doc de implementación en la ruta indicada |

### Reglas generales

1. **Una etapa a la vez** — no saltes a Kubernetes si Catalog no compila.
2. **Elimina placeholders** — borra `Class1.cs`, `Class.cs` y archivos vacíos de plantilla.
3. **No commitees secretos** — usa `.env` (local), user secrets (AppHost) o `k8s/secrets.yaml` (copia de `secrets.example.yaml`).
4. **Migraciones EF** — genéralas con `dotnet ef migrations add`; el repo incluye migraciones de referencia.
5. Tras cada etapa: `dotnet build Source/ShopDemo.slnx` y la validación indicada en la tabla.

### Documentos de código completo (copiar/integrar)

| Etapa | Código completo en |
|---|---|
| Shared Kernel | [ANEXO-CODIGO-SHARED.md](./ANEXO-CODIGO-SHARED.md) |
| Catalog | [catalog/ANEXO-CODIGO-CATALOG.md](./catalog/ANEXO-CODIGO-CATALOG.md) |
| Orders | [orders/ANEXO-CODIGO-ORDERS.md](./orders/ANEXO-CODIGO-ORDERS.md) |
| Inventory | [inventory/ANEXO-CODIGO-INVENTORY.md](./inventory/ANEXO-CODIGO-INVENTORY.md) |
| Event Hubs | [ANEXO-CODIGO-EVENT-HUBS.md](./ANEXO-CODIGO-EVENT-HUBS.md) · [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md) (Portal/CLI) |
| Aspire + Analytics | [analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md](./analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md) |
| MCP Gateway | [integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md](./integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md) · [ANEXO-CODIGO-MCP.md](./integracion-ia/ANEXO-CODIGO-MCP.md) |
| Kubernetes | Carpeta [k8s/](../k8s/) (copiar manifiestos) |
| Docker | `Dockerfile` y `docker-compose.yml` por API |
| Release Azure (CLI) | [Source/scripts/azure/README.md](../Source/scripts/azure/README.md) |
| Release AWS (CLI) | [Source/scripts/aws/README.md](../Source/scripts/aws/README.md) |
| Spec-driven | [spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](../spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) |

---

## Mapa de etapas

| Etapa | Integración | Doc implementación | Validación |
|---|---|---|---|
| 0 | Endpoints y visión | [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) | Postman |
| 1 | Catalog | [IMPLEMENTACION-CATALOG.md](./catalog/IMPLEMENTACION-CATALOG.md) | `POST /api/products` |
| 2 | Orders | [IMPLEMENTACION-ORDERS.md](./orders/IMPLEMENTACION-ORDERS.md) | Crear/confirmar pedido |
| 3 | Inventory + HTTP | [IMPLEMENTACION-INVENTORY.md](./inventory/IMPLEMENTACION-INVENTORY.md) | Stock y reservas |
| 4 | E2E | [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) | Flujo compra |
| 5 | Event Hubs | [ANEXO-CODIGO-EVENT-HUBS](./ANEXO-CODIGO-EVENT-HUBS.md) · [INTEGRACION-AZURE-EVENT-HUBS](./INTEGRACION-AZURE-EVENT-HUBS.md) | Auto-stock + eventos |
| 6 | Aspire + Analytics | [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) | `/api/analytics/events` |
| 7 | Azure ACA | [despliegue/azure/](./despliegue/azure/) · [script §0](./despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md#0-script-powershell-automatizado-recomendado) | FQDN APIs |
| 8 | AWS ECS | [despliegue/aws/](./despliegue/aws/) · [script §0](./despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md#0-script-powershell-automatizado-recomendado) | ALB |
| 9 | Minikube | [despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md](./despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) | `kubectl get pods` |
| 10–11 | AKS / EKS | [aks/](./despliegue/aks/) · [eks/](./despliegue/eks/) | Ingress |
| 12–13 | Observabilidad / Resiliencia | [observabilidad/](./observabilidad/) · [resiliencia/](./resiliencia/) | Logs, health |
| 14–14b | MCP + despliegue | [IMPLEMENTACION-MCP-GATEWAY](./integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md) · [integracion-ia/](./integracion-ia/) | `/mcp` |
| 15 | Spec-driven | [spec-driven/](../spec-driven/) | SPECs |

---

## Etapa 0 — Preparar solución

### Paso 0.1 — Clonar y compilar

```bash
dotnet build Source/ShopDemo.slnx
```

**Para qué:** confirma que .NET 10 SDK y referencias están correctas.

### Paso 0.2 — Importar Postman

Archivo: `Documentación del Proyecto/ShopDemo.postman_collection.json`

**Para qué:** probar APIs en secuencia (carpeta **Health checks** y **Flujo integrado E2E**).

---

## Etapa 1 — Shared Kernel + Catalog

### Paso 1.1 — Shared Kernel (antes de Catalog)

**Copiar desde:** [ANEXO-CODIGO-SHARED.md](./ANEXO-CODIGO-SHARED.md)

| Archivo | Para qué sirve |
|---|---|
| `Entity.cs` | Base de entidades con `Id` |
| `AggregateRoot.cs` | Colección de domain events |
| `ValueObject.cs` | Igualdad por componentes |
| `IDomainEvent.cs` | Contrato de eventos |
| `IRepository.cs` / `IUnitOfWork.cs` | Persistencia genérica |
| `IntegrationEventEnvelope.cs` | (Etapa 5) contrato del bus |

### Paso 1.2 — Crear proyectos Catalog

Comandos en [IMPLEMENTACION-CATALOG.md §2](./catalog/IMPLEMENTACION-CATALOG.md#2-configuración-inicial-de-proyectos).

### Paso 1.3 — Copiar todo el código Catalog

**Copiar desde:** [catalog/ANEXO-CODIGO-CATALOG.md](./catalog/ANEXO-CODIGO-CATALOG.md)

Cada sección del anexo tiene:
- Ruta del archivo (`Source/Catalog/...`)
- Bloque `csharp` completo
- Breve nota de propósito

**Archivos clave y su rol:**

| Archivo | Para qué sirve |
|---|---|
| `Product.cs` | Reglas de negocio del catálogo |
| `CreateProductHandler.cs` | Orquesta comando sin lógica de dominio |
| `ProductConfiguration.cs` | Mapeo EF (owned types) |
| `DependencyInjection.cs` | Registra EF y publisher de eventos |
| `ProductsController.cs` | `POST /api/products` |
| `Program.cs` | Composición DI, migraciones, health |

### Paso 1.4 — Docker Catalog (opcional en etapa 1)

| Archivo | Para qué sirve |
|---|---|
| `Source/Catalog/.../Dockerfile` | Imagen de la API |
| `Source/Catalog/.../docker-compose.yml` | API + PostgreSQL en 8001/5433 |

### Paso 1.5 — Validar

```bash
cd Source/Catalog/ShopDemo.Catalog.Api
docker compose up --build
curl http://localhost:8001/health
```

Postman: **Catalog → Crear producto**.

---

## Etapa 2 — Orders

### Paso 2.1 — Crear proyectos y referencias

Comandos en [IMPLEMENTACION-ORDERS.md §1](./orders/IMPLEMENTACION-ORDERS.md#1-configuración-inicial-de-proyectos).

### Paso 2.2 — Copiar código

**Copiar desde:** [orders/ANEXO-CODIGO-ORDERS.md](./orders/ANEXO-CODIGO-ORDERS.md) — **42 archivos `.cs`** con código completo.

**Explicación arquitectónica:** [IMPLEMENTACION-ORDERS.md](./orders/IMPLEMENTACION-ORDERS.md).

**Archivos críticos:**

| Archivo | Para qué sirve |
|---|---|
| `Order.cs` | Agregado y transiciones de estado |
| `ConfirmOrderHandler.cs` | Confirma pedido (aún sin Inventory en etapa 2 pura) |
| `OrdersController.cs` | REST de pedidos |
| `OrdersDbContext.cs` | Persistencia |

### Paso 2.3 — Validar

```bash
dotnet run --project Source/Orders/ShopDemo.Orders.Api
# o docker compose en Source/Orders/ShopDemo.Orders.Api
```

Postman: crear pedido en estado Pending.

---

## Etapa 3 — Inventory + integración HTTP

### Paso 3.1 — Crear proyectos Inventory

Comandos en [IMPLEMENTACION-INVENTORY.md §2](./inventory/IMPLEMENTACION-INVENTORY.md#2-configuración-inicial-de-proyectos).

### Paso 3.2 — Copiar código Inventory

**Copiar desde:** [inventory/ANEXO-CODIGO-INVENTORY.md](./inventory/ANEXO-CODIGO-INVENTORY.md) — **29 archivos `.cs`** con código completo.

**Explicación arquitectónica:** [IMPLEMENTACION-INVENTORY.md](./inventory/IMPLEMENTACION-INVENTORY.md) (hexagonal, sin snippets abreviados).

**Archivos críticos:**

| Archivo | Para qué sirve |
|---|---|
| `StockEntry.cs` | Agregado de stock |
| `RegisterStockUseCase.cs` | Alta manual de stock |
| `ReserveStockUseCase.cs` | Reserva (lo llama Orders) |
| `StockController.cs` / `ReservationsController.cs` | Adaptadores HTTP |
| `InventoryHttpClient.cs` (en **Orders**) | Cliente HTTP hacia Inventory |

### Paso 3.3 — Integrar Orders → Inventory

En **Orders**, copiar/verificar:

| Archivo | Para qué sirve |
|---|---|
| `IInventoryService.cs` | Puerto en Application |
| `InventoryHttpClient.cs` | Implementación HTTP |
| `DependencyInjection.cs` | Registra HttpClient con `InventoryApi:BaseUrl` |
| `appsettings.json` | `"InventoryApi": { "BaseUrl": "http://localhost:8003" }` |

En Docker Compose de Orders, `InventoryApi__BaseUrl=http://host.docker.internal:8003`.

### Paso 3.4 — Validar flujo E2E manual

Orden: Catalog → Inventory → Orders. Postman: carpeta **Flujo integrado (E2E)**.

---

## Etapa 5 — Azure Event Hubs

### Paso 5.1 — Contrato compartido

Ya en [ANEXO-CODIGO-SHARED.md](./ANEXO-CODIGO-SHARED.md): `IntegrationEventEnvelope.cs`.

### Paso 5.2 — Archivos a agregar o modificar

**Código completo:** [ANEXO-CODIGO-EVENT-HUBS.md](./ANEXO-CODIGO-EVENT-HUBS.md) — publishers, `CatalogEventsProcessor`, DI, appsettings, `.env` y `docker-compose`.

**Portal/CLI Azure:** [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md) paso a paso.

| Servicio | Archivo nuevo/modificado | Para qué sirve |
|---|---|---|
| Catalog | `EventHubsDomainEventPublisher.cs` | Publica eventos al hub |
| Catalog | `DependencyInjection.cs` | Elige publisher según `EventHubs:Enabled` |
| Orders | `EventHubsDomainEventPublisher.cs` | Igual que Catalog |
| Inventory | `EventHubsIntegrationEventPublisher.cs` | Publica eventos de inventario |
| Inventory | `CatalogEventsProcessor.cs` | **Consumidor:** auto-stock al crear producto |
| Cada API | `.env.example` → `.env` | Connection string y flags |
| Cada API | `docker-compose.yml` | Variables `EventHubs__*` |

**Copiar plantilla local:**

```powershell
copy Catalog\ShopDemo.Catalog.Api\.env.example Catalog\ShopDemo.Catalog.Api\.env
# Repetir en Orders, Inventory
```

### Paso 5.3 — Validar

Crear producto → sin `POST /stock` manual → consultar Inventory → debe existir stock. Analytics (etapa 6) lista eventos.

---

## Etapa 6 — Aspire + Analytics

### Paso 6.1 — Proyectos nuevos

| Proyecto | Para qué sirve |
|---|---|
| `ShopDemo.ServiceDefaults` | Health, telemetría, resilience |
| `ShopDemo.Analytics.Api` | Consumidor read-only del bus |
| `ShopDemo.AppHost` | Orquesta 4 APIs + PG + Azurite |

**Código completo:** [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) (explicación) · [ANEXO-CODIGO-ANALYTICS-ASPIRE.md](./analytics/ANEXO-CODIGO-ANALYTICS-ASPIRE.md) (copiar/pegar).

### Paso 6.2 — Configurar Event Hubs en AppHost

```bash
dotnet user-secrets set "ShopDemo:EventHubs:ConnectionString" "<CONNECTION_STRING>" \
  --project Source/Aspire/ShopDemo.AppHost
```

### Paso 6.3 — Ejecutar

```bash
dotnet run --project Source/Aspire/ShopDemo.AppHost
```

**Validar:** `GET http://localhost:8004/api/analytics/events`

---

## Etapas 7–8 — Despliegue Azure / AWS (contenedores)

No hay código C# nuevo; **integras configuración, scripts PowerShell y pipelines**.

### Mapa de servicios cloud (release productivo lab)

| Componente | Azure ACA | AWS ECS | Kubernetes |
|---|---|---|---|
| Registro imágenes | ACR `acrshopdemolab01` (5 repos) | ECR `shopdemo-*` (5) | Imagen local / ACR / ECR |
| APIs + MCP | 5 Container Apps | 5 ECS services + ALB | Compartidos + `k8s/{local,azure,aws}/` |
| PostgreSQL | ACI | Fargate task | StatefulSet `k8s/postgres/` |
| Checkpoints EH | **Storage Account** | **Azurite Fargate** | **Azurite** `k8s/azurite/` |
| Mensajería | Event Hubs (Azure) | Event Hubs cross-cloud | Event Hubs en `secrets.yaml` |
| Secretos | ACA secrets | SSM Parameter Store | `k8s/secrets.yaml` |

> **Alcance lab:** [ALCANCE-LAB-RELEASE](./despliegue/ALCANCE-LAB-RELEASE.md) · Guías separadas: [Script Azure](./despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) · [CLI](./despliegue/azure/GUIA-RELEASE-CLI-AZURE.md) · [Portal](./despliegue/azure/GUIA-RELEASE-PORTAL-AZURE.md) · [Script AWS](./despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) · [CLI AWS](./despliegue/aws/GUIA-RELEASE-CLI-AWS.md) · [Portal AWS](./despliegue/aws/GUIA-RELEASE-PORTAL-AWS.md) · [K8s](./despliegue/kubernetes/GUIA-RELEASE-KUBERNETES.md)

### Etapa 7 — Azure (script recomendado)

```powershell
cd scripts\azure
copy .env.azure.example .env.azure
# Completar AZURE_SUBSCRIPTION_ID, ACR_NAME, EVENT_HUB_NAMESPACE, STORAGE_ACCOUNT_NAME
az login
.\Deploy-AzureShopDemo.ps1 -Mode ACA
# Luego: push imágenes ACR → .github/workflows/deploy-azure.yml
```

| Documento | Contenido |
|---|---|
| [GUIA-RELEASE-SCRIPT-AZURE](./despliegue/azure/GUIA-RELEASE-SCRIPT-AZURE.md) | Configuración y ejecución del script |
| [GUIA-RELEASE-PORTAL-AZURE](./despliegue/azure/GUIA-RELEASE-PORTAL-AZURE.md) | Portal visual (capturas) |
| [Source/scripts/azure/README.md](../Source/scripts/azure/README.md) | Tabla de variables |

### Etapa 8 — AWS (script recomendado)

```powershell
cd scripts\aws
copy .env.aws.example .env.aws
# Completar EVENT_HUBS_CONNECTION_STRING (Azure Portal) y AWS_REGION
aws configure
.\Deploy-AwsShopDemo.ps1 -Mode ECS
# Luego: push imágenes ECR → .github/workflows/deploy-aws.yml
```

| Documento | Contenido |
|---|---|
| [GUIA-RELEASE-SCRIPT-AWS](./despliegue/aws/GUIA-RELEASE-SCRIPT-AWS.md) | Script + IAM (1 política `ShopDemoLabECS`) |
| [GUIA-RELEASE-PORTAL-AWS](./despliegue/aws/GUIA-RELEASE-PORTAL-AWS.md) | Consola visual (capturas) |
| [Source/scripts/aws/README.md](../Source/scripts/aws/README.md) | Variables y modos ECS/EKS |

| Qué copiar/configurar | Para qué sirve |
|---|---|
| `Dockerfile` de cada API | Build de imagen |
| `.env.azure` / `.env.aws` | Variables del script (no commitear) |
| Variables en ACA / ECS / secrets | Connection strings, Event Hubs |
| `.github/workflows/deploy-azure.yml` | CI/CD Azure ACA — **5 imágenes** |
| `.github/workflows/deploy-aws.yml` | CI/CD AWS ECS — **5 imágenes** |
| `.github/workflows/deploy-aks.yml` | CI/CD Azure AKS — build + `kubectl set image` |
| `.github/workflows/deploy-eks.yml` | CI/CD Amazon EKS — build + `kubectl set image` |
| [.github/SECRETS-CHECKLIST.md](../.github/SECRETS-CHECKLIST.md) | Secrets y environments GitHub |
| Build manual 5 servicios | Ver GUIA-RELEASE-SCRIPT-AZURE / GUIA-RELEASE-SCRIPT-AWS |

Docs manuales: [despliegue/azure/](./despliegue/azure/) · [despliegue/aws/](./despliegue/aws/)

---

## Etapa 9–11 — Kubernetes

### Paso 9.1 — Copiar manifiestos

Carpeta completa: [k8s/](../k8s/)

```powershell
copy k8s\secrets.example.yaml k8s\secrets.yaml
# Editar connection strings — NO commitear
```

| Manifiesto | Para qué sirve |
|---|---|
| `namespace.yaml` | Aislamiento `shopdemo` |
| `postgres/` | BD compartida (3 databases) |
| `azurite/` | Checkpoints Event Hubs |
| `catalog/`, `orders/`, … | Deployments + Services + probes |
| `ingress/ingress.yaml` | Rutas `/catalog`, `/orders`, … |
| `mcp/` | MCP Gateway (etapa 14b) |

### Paso 9.2 — Aplicar (orden)

Ver [k8s/README.md](../k8s/README.md).

---

## Etapas 12–13 — Observabilidad y resiliencia

No hay código C# nuevo en el repositorio; **integras configuración en la nube** sobre lo ya desplegado.

| Etapa | Qué configurar | Para qué sirve | Documentación |
|---|---|---|---|
| 12 Observabilidad | Log Analytics / CloudWatch, alertas, `traceId` en middleware | Detectar fallos y correlacionar requests | [observabilidad/azure](./observabilidad/azure/IMPLEMENTACION-OBSERVABILIDAD-AZURE.md) · [aws](./observabilidad/aws/IMPLEMENTACION-OBSERVABILIDAD-AWS.md) |
| 13 Resiliencia | Probes K8s, HPA, políticas de reinicio ACA/ECS | Recuperación tras caída de pod/tarea | [resiliencia/azure](./resiliencia/azure/IMPLEMENTACION-RESILIENCIA-AZURE.md) · [aws](./resiliencia/aws/IMPLEMENTACION-RESILIENCIA-AWS.md) |

**Código ya presente en el repo (no copiar de nuevo):** endpoints `/health` y `/alive` en las APIs; deployments en `k8s/local/`, `k8s/azure/` o `k8s/aws/` con `livenessProbe` y `readinessProbe`.

---

## Etapa 14 — MCP Gateway

### Paso 14.1 — Crear proyecto y copiar código MCP

**Guía paso a paso:** [integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md](./integracion-ia/IMPLEMENTACION-MCP-GATEWAY.md)  
**Código completo:** [integracion-ia/ANEXO-CODIGO-MCP.md](./integracion-ia/ANEXO-CODIGO-MCP.md)

| Archivo | Para qué sirve |
|---|---|
| `Program.cs` | HttpClients + endpoint `/mcp` |
| `ShopDemoMcpTools.cs` | Tools: CreateProduct, GetProductStock, ListAnalyticsEvents, GetShopDemoStatus |
| `.env.example` → `.env` | URLs de Catalog, Inventory, Analytics |

### Paso 14.2 — Ejecutar

```bash
# Requiere 8001, 8003, 8004 activos
dotnet run --project Source/AI/ShopDemo.Mcp.Api
curl http://localhost:8005/health
```

Despliegue nube: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

---

## Etapa 15 — Spec-driven (opcional)

Copiar plantillas desde `spec-driven/cursor/` o `spec-driven/claude-code/` según [IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md](../spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md).

Trabajar siempre contra `spec-driven/specs/<módulo>/SPEC.md`.

---

## Checklist global del alumno

| # | Verificación |
|---|---|
| 1 | `dotnet build Source/ShopDemo.slnx` sin errores |
| 2 | Catalog `POST /api/products` → 201 |
| 3 | Inventory stock + reserva funcionan |
| 4 | Orders confirma y descuenta stock vía HTTP |
| 5 | Event Hubs: auto-stock (opcional etapa 5+) |
| 6 | Analytics lista eventos (etapa 6+) |
| 7 | Postman E2E completo |
| 8 | `/health` en APIs desplegadas |
| 9 | MCP `/health` (etapa 14+) |

---

## Referencias

- [README.md](../README.md) — arranque local y nube
- [RETO-TECNICO-SHOPDEMO.md](./RETO-TECNICO-SHOPDEMO.md) — visión del ejercicio
- [ARQUITECTURA.md](./ARQUITECTURA.md) — diseño técnico
