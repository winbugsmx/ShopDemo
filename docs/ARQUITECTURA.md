# Arquitectura de ShopDemo

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Índice general del curso:** [README.md](../README.md) · **Prueba de APIs:** [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md)  
**Cómo levantar servicios:** [Tabla maestra de arranque](../README.md#tabla-maestra-de-arranque) · [Local](../README.md#inicio-local-desarrollo-y-pruebas) · [Azure](../README.md#release-azure) · [AWS](../README.md#release-aws)

---

## 1. Visión general

**ShopDemo** es una plataforma de e-commerce organizada como **sistema distribuido por bounded contexts**, implementada en **.NET 10**. Cada microservicio de negocio tiene su propia base de datos PostgreSQL y API HTTP independiente. La orquestación local unificada se realiza con **.NET Aspire** (`ShopDemo.AppHost`).

La solución combina dos estilos arquitectónicos de forma intencional en los microservicios de dominio, más un **observador de eventos** orquestado por Aspire y un **MCP Gateway** para agentes IA:

| Microservicio | Estilo arquitectónico | Orquestación |
|---|---|---|
| **Catalog** | Clean Architecture + DDD | CQRS con MediatR |
| **Orders** | Clean Architecture + DDD | CQRS con MediatR |
| **Inventory** | Hexagonal (Ports & Adapters) | Casos de uso + Inbound Ports |
| **Analytics** | API mínima + `BackgroundService` | Consumidor Event Hubs (read-only) |
| **MCP Gateway** | API HTTP + MCP tools | Proxy a Catalog, Inventory, Analytics |
| **AppHost** | .NET Aspire | Orquesta 4 APIs + PostgreSQL + Azurite + config Event Hubs |

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  API (Presentación)                                                          │
│  Catalog (:8001)  Orders (:8002)  Inventory (:8003)  Analytics (:8004)     │
│  MCP Gateway (:8005)                                                       │
├──────────────────────────────────────────────────────────────────────────────┤
│  Infrastructure / Adaptadores Driven                                         │
│  EF Core, HTTP clients, Event Hubs publishers/consumers                      │
├──────────────────────────────────────────────────────────────────────────────┤
│  Application                                                                 │
│  Commands/Queries (MediatR)  │  Use Cases + Ports (Hexagonal)                │
├──────────────────────────────────────────────────────────────────────────────┤
│  Domain                                                                      │
│  Aggregates, Value Objects, Domain Events, Repositories                      │
├──────────────────────────────────────────────────────────────────────────────┤
│  Shared Kernel — ShopDemo.Shared                                             │
│  Entity, AggregateRoot, ValueObject, IRepository, IntegrationEventEnvelope   │
├──────────────────────────────────────────────────────────────────────────────┤
│  Orquestación — Aspire/ShopDemo.AppHost                                      │
│  PostgreSQL ×3, Azurite, Event Hubs config, service discovery, dashboard     │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 1.1 Roadmap de etapas (práctica del curso)

La solución se construye y valida en **etapas incrementales**. En cada una conviene leer el documento de **requerimientos** (el qué y el por qué) y el de **implementación** (el cómo).

```mermaid
flowchart LR
    E1[Etapa 1\nCatalog] --> E2[Etapa 2\nOrders]
    E2 --> E3[Etapa 3\nInventory]
    E3 --> E4[Etapa 4\nE2E HTTP]
    E4 --> E5[Etapa 5\nEvent Hubs]
    E5 --> E6[Etapa 6\nAspire + Analytics]
    E6 --> E7[Etapa 7\nAzure ACA]
    E6 --> E8[Etapa 8\nAWS ECS]
    E7 --> E9[Etapa 9–11\nK8s Minikube/AKS/EKS]
    E8 --> E9
    E9 --> E12[Etapa 12–13\nObservabilidad + Resiliencia]
    E12 --> E14[Etapa 14\nIA + MCP]
    E14 --> E15[Etapa 15\nSpec-driven]
```

| Etapa | Entregable | Requerimientos | Implementación | Validación |
|---|---|---|---|---|
| 0 | Entender el dominio | — | [GUIA-ENDPOINTS](./GUIA-ENDPOINTS.md) | Postman E2E |
| 1 | Catalog API | [catalog/REQUERIMIENTOS-CATALOG](./catalog/REQUERIMIENTOS-CATALOG.md) | [catalog/IMPLEMENTACION-CATALOG](./catalog/IMPLEMENTACION-CATALOG.md) | `POST /api/products` |
| 2 | Orders API | [orders/REQUERIMIENTOS-ORDERS](./orders/REQUERIMIENTOS-ORDERS.md) | [orders/IMPLEMENTACION-ORDERS](./orders/IMPLEMENTACION-ORDERS.md) | Confirmar pedido |
| 3 | Inventory API | [inventory/REQUERIMIENTOS-INVENTORY](./inventory/REQUERIMIENTOS-INVENTORY.md) | [inventory/IMPLEMENTACION-INVENTORY](./inventory/IMPLEMENTACION-INVENTORY.md) | Reserva/liberación stock |
| 4 | Flujo integrado | [GUIA-ENDPOINTS](./GUIA-ENDPOINTS.md) | §4 de este documento | Compra completa |
| 5 | Mensajería Azure | [INTEGRACION-AZURE-EVENT-HUBS](./INTEGRACION-AZURE-EVENT-HUBS.md) | Mismo documento | Auto-stock por evento |
| 6 | Orquestación Aspire | [analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE](./analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) | [analytics/IMPLEMENTACION-ANALYTICS-ASPIRE](./analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) | `/api/analytics/events` |
| 7 | Contenedores en Azure | [despliegue/azure/REQUERIMIENTOS](./despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) | [despliegue/azure/IMPLEMENTACION](./despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) | ACA + ACR |
| 8 | Contenedores en AWS | [despliegue/aws/REQUERIMIENTOS](./despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) | [despliegue/aws/IMPLEMENTACION](./despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) | ECS + ECR |
| 9 | Kubernetes local | [despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES](./despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md) | [IMPLEMENTACION-KUBERNETES-LOCAL](./despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) | `kubectl get pods -n shopdemo` |
| 10 | Azure AKS | [despliegue/aks/REQUERIMIENTOS-DESPLIEGUE-AKS](./despliegue/aks/REQUERIMIENTOS-DESPLIEGUE-AKS.md) | [IMPLEMENTACION-DESPLIEGUE-AKS](./despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) | Ingress + HPA |
| 11 | Amazon EKS | [despliegue/eks/REQUERIMIENTOS-DESPLIEGUE-EKS](./despliegue/eks/REQUERIMIENTOS-DESPLIEGUE-EKS.md) | [IMPLEMENTACION-DESPLIEGUE-EKS](./despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) | Ingress + HPA |
| 12 | Observabilidad | [observabilidad/REQUERIMIENTOS](./observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) | [Azure](./observabilidad/azure/) · [AWS](./observabilidad/aws/) | Logs + traceId |
| 13 | Resiliencia | [resiliencia/REQUERIMIENTOS](./resiliencia/REQUERIMIENTOS-RESILIENCIA.md) | [Azure](./resiliencia/azure/) · [AWS](./resiliencia/aws/) | `/health` + recuperación |
| 14 | Integración IA + MCP | [integracion-ia/REQUERIMIENTOS](./integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) | [Azure](./integracion-ia/azure/) · [AWS](./integracion-ia/aws/) | Tools MCP + alertas |
| 14b | Despliegue MCP | [REQUERIMIENTOS-DESPLIEGUE-MCP](./integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) | [Azure](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) | `curl .../mcp` |
| 15 | Spec-driven | [spec-driven/REQUERIMIENTOS](../spec-driven/REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) | [IMPLEMENTACION](../spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) | Agente + SPEC.md |

**Índice completo de etapas:** [README.md](../README.md#etapas-del-curso-roadmap)

---

## 1.2 Modos de ejecución y arranque

| Modo | Cuándo usarlo | Cómo levantar | Servicios incluidos |
|---|---|---|---|
| **Docker Compose** | Etapas 1–5; un servicio aislado | `docker compose up --build` en cada `*.Api/` | 1 API + su PostgreSQL (+ Azurite en Inventory/Analytics) |
| **Aspire AppHost** | Etapa 6; stack integrado | `dotnet run --project Aspire/ShopDemo.AppHost` | Catalog, Orders, Inventory, Analytics + PG + Azurite |
| **dotnet run** | Depuración unitaria | `dotnet run --project <Api>.csproj` | 1 API (requiere BD/dependencias manuales) |
| **MCP Gateway** | Etapa 14+; agentes IA | `dotnet run --project AI/ShopDemo.Mcp.Api` | MCP :8005 (requiere Catalog, Inventory, Analytics) |
| **Minikube + k8s/** | Etapa 9; practicar K8s | `kubectl apply -f k8s/` | 5 APIs + PostgreSQL + Azurite + Ingress |
| **Azure ACA** | Release serverless | [despliegue/azure/](./despliegue/azure/) | 5 Container Apps + ACR |
| **Azure AKS** | Release Kubernetes | [despliegue/aks/](./despliegue/aks/) + [k8s/](../k8s/) | Manifiestos `k8s/` en cluster AKS |
| **AWS ECS** | Release sin K8s | [despliegue/aws/](./despliegue/aws/) | 5 task definitions + ALB |
| **AWS EKS** | Release Kubernetes | [despliegue/eks/](./despliegue/eks/) + [k8s/](../k8s/) | Mismos manifiestos que Minikube/AKS |

### Orden de arranque (local)

```
Catalog (8001) → Inventory (8003) → Orders (8002) → Analytics (8004) → MCP (8005)
```

Orders depende de Inventory por HTTP. MCP depende de Catalog, Inventory y Analytics.

### Verificación de salud

Todas las APIs de negocio exponen **`GET /health`** y **`GET /alive`** (liveness). En Kubernetes, los manifiestos `k8s/*/deployment.yaml` usan estas rutas en probes HTTP.

```bash
curl http://localhost:8001/health   # Catalog
curl http://localhost:8002/health   # Orders
curl http://localhost:8003/health   # Inventory
curl http://localhost:8004/health   # Analytics
curl http://localhost:8005/health   # MCP Gateway
```

**Guía detallada de arranque:** [README.md § Inicio local](../README.md#inicio-local-desarrollo-y-pruebas) · [README.md § Tabla maestra](../README.md#tabla-maestra-de-arranque) · [README.md § Release Azure/AWS](../README.md#release-azure)

---

## 1.3 Matriz de configuración

Variables en formato ASP.NET Core (`Section__Key`). Origen según modo de ejecución:

| Variable | Catalog | Orders | Inventory | Analytics | AppHost |
|---|---|---|---|---|---|
| `ConnectionStrings__DefaultConnection` | ✅ | ✅ | ✅ | — | — (Aspire inyecta por referencia PG) |
| `InventoryApi__BaseUrl` | — | ✅ | — | — | Aspire: auto |
| `EventHubs__Enabled` | ✅ | ✅ | ✅ | ✅ | `ShopDemo:EventHubs:Enabled` |
| `EventHubs__ConnectionString` | ✅ | ✅ | ✅ | ✅ | `ShopDemo:EventHubs:ConnectionString` |
| `EventHubs__EventHubName` | ✅ | ✅ | ✅ | ✅ | `ShopDemo:EventHubs:EventHubName` |
| `EventHubs__ConsumerGroup` | — | — | ✅ | ✅ | AppHost inyecta |
| `EventHubs__CheckpointStorageConnectionString` | — | — | ✅ | ✅ | AppHost / Azurite |
| `EventHubs__CheckpointContainerName` | — | — | ✅ | ✅ | AppHost inyecta |

**Archivos locales:**

| Servicio | `appsettings.json` | `.env` (compose) | User secrets |
|---|---|---|---|
| Catalog | `Catalog/.../appsettings.json` | `.env.example` → `.env` | Opcional |
| Orders | `Orders/.../appsettings.json` | `.env.example` → `.env` | Opcional |
| Inventory | `Inventory/.../appsettings.json` | `.env.example` → `.env` | Opcional |
| Analytics | `Aspire/.../appsettings.json` | `.env.example` → `.env` | Opcional |
| AppHost | `appsettings.Development.json` | — | **Recomendado** para EH |

**Nube:** secretos en Container Apps (Azure), SSM/Secrets Manager (AWS) o GitHub Actions secrets. Detalle en [despliegue/README.md](./despliegue/README.md).

---

## 2. Estructura de la solución

La solución (`ShopDemo.slnx`) contiene **17 proyectos**:

| Carpeta | Proyecto | Rol |
|---|---|---|
| — | `ShopDemo.Shared` | Kernel compartido DDD + contrato de mensajería |
| Catalog | `ShopDemo.Catalog.Domain` | Modelo de dominio del catálogo |
| Catalog | `ShopDemo.Catalog.Application` | CQRS — comandos y consultas |
| Catalog | `ShopDemo.Catalog.Infraestructure` | EF Core, Event Hubs publisher |
| Catalog | `ShopDemo.Catalog.Api` | API HTTP del catálogo |
| Orders | `ShopDemo.Orders.Domain` | Modelo de dominio de pedidos |
| Orders | `ShopDemo.Orders.Application` | CQRS — comandos y consultas |
| Orders | `ShopDemo.Orders.Infraestructure` | EF Core, HTTP a Inventory, Event Hubs |
| Orders | `ShopDemo.Orders.Api` | API HTTP de pedidos |
| Inventory | `ShopDemo.Inventory.Domain` | Núcleo de inventario |
| Inventory | `ShopDemo.Inventory.Application` | Puertos y casos de uso |
| Inventory | `ShopDemo.Inventory.Infrastructure` | EF Core, Event Hubs pub/sub |
| Inventory | `ShopDemo.Inventory.Api` | API HTTP de inventario |
| Aspire | `ShopDemo.AppHost` | Orquestador Aspire (4 APIs + infra) |
| Aspire | `ShopDemo.ServiceDefaults` | Telemetría, health, service discovery |
| Aspire | `ShopDemo.Analytics.Api` | Observador Event Hubs + API de consulta |
| AI | `ShopDemo.Mcp.Api` | MCP Server HTTP — tools para agentes IA |

### Regla de dependencias

```
Api → Infrastructure → Application → Domain → Shared
```

- **Domain** solo referencia `Shared`.
- **Application** referencia `Domain` (y opcionalmente `Shared`).
- **Infrastructure** implementa puertos definidos en capas superiores.
- **Api** compone DI y expone HTTP.

---

## 3. Microservicios y puertos

| Servicio | Puerto API | PostgreSQL (host) | Base de datos | Arquitectura | Health |
|---|---|---|---|---|---|
| **Catalog** | 8001 | 5433* | `ShopDemoCatalog` | Clean + CQRS | `/health`, `/alive` |
| **Orders** | 8002 | 5434* | `ShopDemoOrders` | Clean + CQRS | `/health`, `/alive` |
| **Inventory** | 8003 | 5435* | `ShopDemoInventory` | Hexagonal | `/health`, `/alive` |
| **Analytics** | 8004 | — | — (buffer en memoria) | Observador Event Hubs | `/health` vía ServiceDefaults |
| **MCP Gateway** | 8005 | — | — | MCP HTTP tools | `/health` |
| **Aspire Dashboard** | ~15888 | — | — | Orquestación local | — |

\* Con **Docker Compose** cada servicio usa su propio contenedor PostgreSQL en el puerto indicado. Con **Aspire AppHost** se usa un servidor PostgreSQL compartido con tres bases de datos.

### Orquestación con Aspire

```bash
dotnet run --project Aspire/ShopDemo.AppHost
```

El AppHost levanta los 4 APIs, PostgreSQL (3 DBs), Azurite (checkpoints Event Hubs), inyecta `EventHubs__*` y resuelve `InventoryApi__BaseUrl` para Orders vía **service discovery**. Los `Program.cs` de Catalog, Orders e Inventory **no se modifican** en Fase 1.

**Documentación:** [docs/analytics/](./analytics/) · [INTEGRACION-ASPIRE.md](./INTEGRACION-ASPIRE.md)

---

## 4. Integración entre bounded contexts

### 4.1 Flujo de negocio integrado

```mermaid
sequenceDiagram
    participant C as Catalog :8001
    participant I as Inventory :8003
    participant O as Orders :8002

    C->>C: POST /api/products → ProductId
    I->>I: POST /api/inventory/stock (ProductId)
    O->>O: POST /api/orders (líneas con ProductId)
    O->>I: POST /api/inventory/reservations (al confirmar)
    O->>I: POST /api/inventory/reservations/release (al cancelar)
    I->>I: GET /api/inventory/{productId}
```

Con **Event Hubs habilitado**, el paso de registro de stock puede ocurrir de forma automática: Catalog publica `ProductCreatedDomainEvent` → Inventory (`inventory-service`) crea stock sin llamada HTTP. Analytics (`analytics-service`) observa el mismo evento en paralelo.

### 4.2 Integración síncrona (implementada)

| Origen | Destino | Mecanismo | Cuándo |
|---|---|---|---|
| Orders | Inventory | HTTP (`IInventoryService` → `InventoryHttpClient`) | Confirmar / cancelar pedido |

Orders no conoce el dominio de Inventory; solo consume su contrato HTTP.

### 4.3 Integración asíncrona (Azure Event Hubs)

Los tres microservicios de negocio publican **Domain Events** a **Azure Event Hubs** cuando `EventHubs:Enabled = true`. El contrato común es `IntegrationEventEnvelope` en `ShopDemo.Shared`.

```
┌──────────────┐    IntegrationEventEnvelope    ┌──────────────────────┐
│ Catalog      │ ─────────────────────────────► │ Azure Event Hubs     │
│ Orders       │ ─────────────────────────────► │ (shopdemo-events)    │
│ Inventory    │ ─────────────────────────────► └──────────┬───────────┘
└──────────────┘                                          │
                              ┌───────────────────────────┼───────────────────────────┐
                              ▼                           ▼                           │
                    inventory-service            analytics-service                    │
                              │                           │                           │
                              ▼                           ▼                           │
                    CatalogEventsProcessor        EventHubAnalyticsProcessor          │
                    (auto-stock ProductCreated)   (observador read-only)            │
                              │                           │                           │
                              ▼                           ▼                           │
                    Inventory.Api :8003           Analytics.Api :8004                 │
                    POST stock automático         GET /api/analytics/events           │
```

| Consumer group | Servicio | Comportamiento |
|---|---|---|
| `inventory-service` | Inventory | Reacciona a `ProductCreatedDomainEvent` — registra stock automáticamente |
| `analytics-service` | Analytics | Observa **todos** los eventos; los expone vía HTTP sin lógica de negocio |

**Fan-out:** un mismo evento publicado por Catalog es consumido de forma independiente por Inventory (efecto de negocio) y Analytics (auditoría/BI en memoria).

**Checkpoints:** Inventory y Analytics persisten progreso en Azure Blob Storage (Azurite en desarrollo local / Aspire).

**Configuración:** centralizada en `ShopDemo.AppHost` o por servicio vía `docker-compose` + `.env`. Ver [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md).

> Con Event Hubs deshabilitado (`EventHubs:Enabled = false`), los adaptadores de logging siguen activos y el registro manual de stock en Inventory permanece disponible.

---

## 5. Shared Kernel (`ShopDemo.Shared`)

| Abstracción | Responsabilidad |
|---|---|
| `Entity<TId>` | Identidad tipada, comparación por `Id` (`protected set` en `Id`) |
| `AggregateRoot<TId>` | Gestión de `DomainEvents` |
| `ValueObject` | Igualdad por componentes |
| `IDomainEvent` | `EventId`, `OccurredOn` (`DateTimeOffset`) |
| `IRepository<TAggregate, TId>` | CRUD genérico |
| `IUnitOfWork` | `SaveChangesAsync()` |
| `IntegrationEventEnvelope` | Contrato JSON para Event Hubs (`EventType`, `EventId`, `Source`, `PayloadJson`) |

---

## 6. Bounded Context: Catalog

**Documentación:** [docs/catalog/](./catalog/)

### 6.1 Estado de implementación

| Componente | Estado |
|---|---|
| Domain (agregado, VOs, eventos, repositorio) | ✅ Completo |
| Application (CreateProduct + validación) | ✅ MVP |
| Infrastructure (EF Core, migraciones, eventos) | ✅ Completo |
| API (`POST /api/products`, Swagger) | ✅ MVP |
| Queries CQRS adicionales | ⏳ Preparado |

### 6.2 Agregado `Product`

```
Product (Aggregate Root)
├── ProductName      (Value Object)
├── Money            (Value Object) — precio
├── StockLevel       (Value Object) — inventario en catálogo
├── Category         (Value Object)
├── Description      (string)
├── IsActive         (bool)
├── CreatedAt        (DateTimeOffset)
└── LastUpdatedAt    (DateTimeOffset?)
```

**Comportamientos:** `Create`, `UpdateDetails`, `ChangePrice`, `ReplenishStock`, `DeductStock`, `Deactivate`, `HasSufficientStock`.

**Endpoint expuesto:** `POST /api/products`

### 6.3 Flujo CreateProduct (CQRS)

```mermaid
sequenceDiagram
    participant API as ProductsController
    participant M as MediatR
    participant V as CreateProductValidator
    participant H as CreateProductHandler
    participant D as Product
    participant R as ProductRepository
    participant P as EventPublisher

    API->>M: CreateProductCommand
    M->>V: Validar
    M->>H: Handle
    H->>D: Product.Create(...)
    H->>R: AddAsync + SaveChanges
    H->>P: PublishAsync(events)
    H-->>API: ProductDto
```

---

## 7. Bounded Context: Orders

**Documentación:** [docs/orders/](./orders/)

### 7.1 Estado de implementación

| Componente | Estado |
|---|---|
| Domain (`Order`, `OrderLine`, VOs, eventos) | ✅ Completo |
| Application (Place, Confirm, Cancel, queries) | ✅ Completo |
| Infrastructure (EF Core + HTTP Inventory) | ✅ Completo |
| API (OrdersController, Swagger) | ✅ Completo |

### 7.2 Agregado `Order`

Ciclo de vida: `Pending` → `Confirmed` → `Shipped` → `Delivered` / `Cancelled`.

**Integración con Inventory:** al confirmar, `ConfirmOrderHandler` llama `IInventoryService.ReserveStockAsync`. Al cancelar un pedido confirmado, `CancelOrderHandler` llama `ReleaseStockAsync`.

---

## 8. Bounded Context: Inventory

**Documentación:** [docs/inventory/](./inventory/)

### 8.1 Estado de implementación

| Componente | Estado |
|---|---|
| Domain (`StockEntry`, VOs, eventos) | ✅ Completo |
| Application (puertos + use cases) | ✅ Completo |
| Infrastructure (EF Core, migraciones) | ✅ Completo |
| API (stock + reservations, Swagger) | ✅ Completo |

### 8.2 Arquitectura hexagonal

| Tipo | Implementación |
|---|---|
| Driving adapters | `StockController`, `ReservationsController` |
| Inbound ports | `IRegisterStockUseCase`, `IGetStockByProductUseCase`, `IReserveStockUseCase`, `IReleaseStockUseCase` |
| Outbound ports | `IStockEntryRepository`, `IIntegrationEventPublisher` |
| Driven adapters | `StockEntryRepository`, `EventHubsIntegrationEventPublisher`, `CatalogEventsProcessor` |

**Endpoints:**

- `POST /api/inventory/stock`
- `GET /api/inventory/{productId}`
- `POST /api/inventory/reservations`
- `POST /api/inventory/reservations/release`

### 8.3 Consumidor Event Hubs (`CatalogEventsProcessor`)

Cuando Event Hubs está habilitado, Inventory escucha `ProductCreatedDomainEvent` del bus y ejecuta `RegisterStock` automáticamente (consumer group `inventory-service`). Esto complementa — no reemplaza — el endpoint manual `POST /api/inventory/stock`.

---

## 9. Bounded Context: Analytics (Aspire)

**Documentación:** [docs/analytics/](./analytics/)

### 9.1 Estado de implementación

| Componente | Estado |
|---|---|
| `EventHubAnalyticsProcessor` (consumer group `analytics-service`) | ✅ Completo |
| `InMemoryEventStore` (ring buffer, máx. 100 eventos) | ✅ Completo |
| API (`GET /api/analytics/events`, Swagger) | ✅ Completo |
| `ShopDemo.ServiceDefaults` (telemetría Aspire) | ✅ Completo |
| `ShopDemo.AppHost` (orquestación 4 APIs) | ✅ Completo |

### 9.2 Rol arquitectónico

Analytics **no es un bounded context de negocio** con dominio propio; es un **observador transversal** del bus de eventos:

| Atributo | Valor |
|---|---|
| Acoplamiento con Catalog/Orders/Inventory | Solo asíncrono (mismo Event Hub) |
| Lógica de negocio | Ninguna — read-only |
| Persistencia | Memoria (MVP); sin PostgreSQL |
| Consumer group | `analytics-service` (offset independiente de Inventory) |

**Endpoints:**

- `GET /api/analytics/events?take=50` — últimos eventos observados
- `GET /api/analytics/health` — estado del servicio

---

## 10. MCP Gateway (integración IA)

**Documentación:** [docs/integracion-ia/](./integracion-ia/) · [AI/README.md](../AI/README.md)

### 10.1 Estado de implementación

| Componente | Estado |
|---|---|
| `ShopDemo.Mcp.Api` (HTTP transport `/mcp`) | ✅ Completo |
| Tools: `CreateProduct`, `GetProductStock`, `ListAnalyticsEvents`, `GetShopDemoStatus` | ✅ Completo |
| Docker + `docker-compose.yml` | ✅ Completo |
| Manifiestos K8s (`k8s/mcp/`) + Ingress `/mcp` | ✅ Completo |
| Despliegue ACA/AKS y ECS/EKS | ✅ Documentado |

### 10.2 Rol arquitectónico

El MCP Gateway **no participa en el flujo de negocio** de pedidos; expone **herramientas** para agentes IA (Cursor, Claude Code) que invocan APIs existentes:

| Atributo | Valor |
|---|---|
| Puerto | 8005 |
| Endpoint MCP | `http://<host>:8005/mcp` |
| Dependencias HTTP | Catalog (:8001), Inventory (:8003), Analytics (:8004) |
| Persistencia | Ninguna |
| Orquestación Aspire | No incluido en AppHost (arranque manual o Docker) |

### 10.3 Arranque

```bash
# Requiere Catalog, Inventory y Analytics activos
dotnet run --project AI/ShopDemo.Mcp.Api
curl http://localhost:8005/health
```

Docker: `AI/ShopDemo.Mcp.Api/docker-compose.yml`  
Nube: [IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md)

---

## 11. Diagrama de componentes

```mermaid
graph TB
    subgraph "Aspire AppHost"
        AH[ShopDemo.AppHost]
        SD[ServiceDefaults]
        DASH[Aspire Dashboard]
        AH --> DASH
    end

    subgraph "Catalog (Clean Architecture)"
        CA[Catalog.Api :8001]
        CApp[Catalog.Application]
        CD[Catalog.Domain]
        CI[Catalog.Infraestructure]
        CA --> CApp & CI
        CI --> CApp --> CD
    end

    subgraph "Orders (Clean Architecture)"
        OA[Orders.Api :8002]
        OApp[Orders.Application]
        OD[Orders.Domain]
        OI[Orders.Infraestructure]
        OA --> OApp & OI
        OI --> OApp --> OD
    end

    subgraph "Inventory (Hexagonal)"
        IA[Inventory.Api :8003]
        IApp[Inventory.Application]
        ID[Inventory.Domain]
        II[Inventory.Infrastructure]
        IA --> IApp & II
        II --> IApp --> ID
    end

    subgraph "Analytics (Observador)"
        AA[Analytics.Api :8004]
        AP[EventHubAnalyticsProcessor]
        AS[InMemoryEventStore]
        AA --> AS
        AP --> AS
        AA -.-> SD
    end

    subgraph "MCP Gateway (IA)"
        MA[Mcp.Api :8005]
        MT[ShopDemoMcpTools]
        MA --> MT
        MT -->|HTTP tools| CA & IA & AA
    end

    subgraph "Shared + Infraestructura"
        SK[ShopDemo.Shared]
        PG1[(PG Catalog)]
        PG2[(PG Orders)]
        PG3[(PG Inventory)]
        EH[Azure Event Hubs]
        AZ[Azurite / Blob checkpoints]
    end

    AH --> CA & OA & IA & AA
    CD & OD & ID --> SK
    CI --> PG1 & EH
    OI --> PG2 & EH
    OI -->|HTTP reserve/release| IA
    II --> PG3 & EH & AZ
    AP --> EH & AZ
    EH -->|inventory-service| II
    EH -->|analytics-service| AP
```

---

## 12. Despliegue y operación

### 12.1 Docker Compose (por microservicio)

Cada API tiene su propio `docker-compose.yml`:

| Servicio | Ubicación compose | API | PostgreSQL | Notas |
|---|---|---|---|---|
| Catalog | `Catalog/ShopDemo.Catalog.Api/` | 8001 | 5433 | Health `/health` |
| Orders | `Orders/ShopDemo.Orders.Api/` | 8002 | 5434 | `InventoryApi__BaseUrl` → host |
| Inventory | `Inventory/ShopDemo.Inventory.Api/` | 8003 | 5435 | Incluye Azurite |
| Analytics | `Aspire/ShopDemo.Analytics.Api/` | 8004 | — | Azurite en compose |
| MCP Gateway | `AI/ShopDemo.Mcp.Api/` | 8005 | — | URLs de APIs en `.env` |

Patrón común:

- Imagen PostgreSQL 16 Alpine (donde aplica)
- Healthcheck `pg_isready` antes de levantar la API
- Dockerfile multi-stage .NET 10 con usuario no-root
- Migraciones EF aplicadas al iniciar (`MigrateAsync`)

**Arranque:** ver [README.md § Opción A](../README.md#opción-a--docker-compose-recomendada-para-empezar).

### 12.2 .NET Aspire (orquestación integrada)

| Componente | Ubicación | Rol |
|---|---|---|
| AppHost | `Aspire/ShopDemo.AppHost/` | Arranque unificado de 4 APIs + infra |
| ServiceDefaults | `Aspire/ShopDemo.ServiceDefaults/` | Telemetría y health |
| Analytics | `Aspire/ShopDemo.Analytics.Api/` | Observador Event Hubs |

```bash
dotnet run --project Aspire/ShopDemo.AppHost
```

MCP **no** forma parte del AppHost; levántalo por separado en etapa 14.

### 12.3 Kubernetes (`k8s/`)

Manifiestos compartidos para **Minikube**, **AKS** y **EKS**:

| Recurso | Carpeta | Rol |
|---|---|---|
| Namespace + secrets | `k8s/namespace.yaml`, `secrets.example.yaml` | Aislamiento `shopdemo` |
| PostgreSQL | `k8s/postgres/` | StatefulSet (3 bases) |
| Azurite | `k8s/azurite/` | Checkpoints Event Hubs |
| APIs | `k8s/catalog/`, `orders/`, `inventory/`, `analytics/`, `mcp/` | Deployments + Services + probes |
| HPA | `k8s/catalog/hpa.yaml` | Demo autoscaling Catalog |
| Ingress | `k8s/ingress/` | Rutas `/catalog`, `/orders`, `/inventory`, `/analytics`, `/mcp` |

Orden de apply: [k8s/README.md](../k8s/README.md)

### 12.4 Despliegue en nube (Azure / AWS)

| Plataforma | Cómputo | Imágenes | Guía arranque |
|---|---|---|---|
| **Azure ACA** | Container Apps (5 apps) | ACR | [despliegue/azure/](./despliegue/azure/) |
| **Azure AKS** | Kubernetes | ACR + `k8s/` | [despliegue/aks/](./despliegue/aks/) |
| **AWS ECS** | Fargate (5 services) | ECR | [despliegue/aws/](./despliegue/aws/) |
| **Amazon EKS** | Kubernetes | ECR + `k8s/` | [despliegue/eks/](./despliegue/eks/) |

Cada guía incluye pasos por **Portal/Consola** y **CLI**. CI/CD: [.github/workflows/deploy-azure.yml](../.github/workflows/deploy-azure.yml) · [deploy-aws.yml](../.github/workflows/deploy-aws.yml).

**Post-despliegue:** configurar Postman con FQDN/ALB/Ingress según [README.md § Postman](../README.md#configurar-postman-según-entorno).

### 12.5 Observabilidad y resiliencia (operación)

| Tema | Qué aporta al arranque | Documentación |
|---|---|---|
| **Observabilidad** | Logs, métricas, `traceId` en errores | [observabilidad/](./observabilidad/) |
| **Resiliencia** | Probes K8s, HPA, recuperación de pods | [resiliencia/](./resiliencia/) |
| **Health endpoints** | `/health` (readiness), `/alive` (liveness) | Manifiestos `k8s/*/deployment.yaml` |

---

## 13. Documentación por microservicio

| Microservicio | Requerimientos | Implementación |
|---|---|---|
| Catalog | [REQUERIMIENTOS-CATALOG.md](./catalog/REQUERIMIENTOS-CATALOG.md) | [IMPLEMENTACION-CATALOG.md](./catalog/IMPLEMENTACION-CATALOG.md) |
| Orders | [REQUERIMIENTOS-ORDERS.md](./orders/REQUERIMIENTOS-ORDERS.md) | [IMPLEMENTACION-ORDERS.md](./orders/IMPLEMENTACION-ORDERS.md) |
| Inventory | [REQUERIMIENTOS-INVENTORY.md](./inventory/REQUERIMIENTOS-INVENTORY.md) | [IMPLEMENTACION-INVENTORY.md](./inventory/IMPLEMENTACION-INVENTORY.md) |
| Analytics + Aspire | [REQUERIMIENTOS-ANALYTICS-ASPIRE.md](./analytics/REQUERIMIENTOS-ANALYTICS-ASPIRE.md) | [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./analytics/IMPLEMENTACION-ANALYTICS-ASPIRE.md) |
| Despliegue Azure | [REQUERIMIENTOS-DESPLIEGUE-AZURE.md](./despliegue/azure/REQUERIMIENTOS-DESPLIEGUE-AZURE.md) | [IMPLEMENTACION-DESPLIEGUE-AZURE.md](./despliegue/azure/IMPLEMENTACION-DESPLIEGUE-AZURE.md) |
| Despliegue AWS | [REQUERIMIENTOS-DESPLIEGUE-AWS.md](./despliegue/aws/REQUERIMIENTOS-DESPLIEGUE-AWS.md) | [IMPLEMENTACION-DESPLIEGUE-AWS.md](./despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md) |
| Kubernetes local | [REQUERIMIENTOS-KUBERNETES.md](./despliegue/kubernetes/REQUERIMIENTOS-KUBERNETES.md) | [IMPLEMENTACION-KUBERNETES-LOCAL.md](./despliegue/kubernetes/IMPLEMENTACION-KUBERNETES-LOCAL.md) |
| Azure AKS | [REQUERIMIENTOS-DESPLIEGUE-AKS.md](./despliegue/aks/REQUERIMIENTOS-DESPLIEGUE-AKS.md) | [IMPLEMENTACION-DESPLIEGUE-AKS.md](./despliegue/aks/IMPLEMENTACION-DESPLIEGUE-AKS.md) |
| Amazon EKS | [REQUERIMIENTOS-DESPLIEGUE-EKS.md](./despliegue/eks/REQUERIMIENTOS-DESPLIEGUE-EKS.md) | [IMPLEMENTACION-DESPLIEGUE-EKS.md](./despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md) |
| MCP Gateway | [REQUERIMIENTOS-DESPLIEGUE-MCP.md](./integracion-ia/REQUERIMIENTOS-DESPLIEGUE-MCP.md) | [Azure](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AZURE.md) · [AWS](./integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md) |
| Observabilidad | [REQUERIMIENTOS-OBSERVABILIDAD.md](./observabilidad/REQUERIMIENTOS-OBSERVABILIDAD.md) | [Azure](./observabilidad/azure/) · [AWS](./observabilidad/aws/) |
| Resiliencia | [REQUERIMIENTOS-RESILIENCIA.md](./resiliencia/REQUERIMIENTOS-RESILIENCIA.md) | [Azure](./resiliencia/azure/) · [AWS](./resiliencia/aws/) |
| Integración IA | [REQUERIMIENTOS-INTEGRACION-IA.md](./integracion-ia/REQUERIMIENTOS-INTEGRACION-IA.md) | [Azure](./integracion-ia/azure/) · [AWS](./integracion-ia/aws/) |
| Spec-driven | [REQUERIMIENTOS-SPEC-DRIVEN](../spec-driven/REQUERIMIENTOS-SPEC-DRIVEN-DEVELOPMENT.md) | [IMPLEMENTACION](../spec-driven/IMPLEMENTACION-SPEC-DRIVEN-DEVELOPMENT.md) |

**Integración transversal:**

| Tema | Documento |
|---|---|
| Azure Event Hubs | [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md) |
| .NET Aspire | [INTEGRACION-ASPIRE.md](./INTEGRACION-ASPIRE.md) |
| Endpoints y flujos de prueba | [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) |

---

## 14. Estado de madurez por componente

| Componente | Estado | Completitud |
|---|---|---|
| Shared Kernel | Implementado | ~95% |
| Catalog — Domain | Implementado | ~90% |
| Catalog — Application (commands) | MVP (CreateProduct) | ~40% |
| Catalog — Application (queries) | Pendiente | 0% |
| Catalog — Infrastructure | Implementado | ~95% |
| Catalog — API | MVP (1 endpoint) | ~30% |
| Orders — completo | Implementado | ~90% |
| Inventory — completo | Implementado | ~90% |
| Integración Orders → Inventory | Implementada (HTTP) | ~85% |
| Azure Event Hubs (publishers) | Implementado (Catalog, Orders, Inventory) | ~90% |
| Event Hubs consumer Inventory | Implementado (`CatalogEventsProcessor`) | ~85% |
| Analytics + Aspire AppHost | Implementado | ~85% |
| MCP Gateway | Implementado | ~85% |
| Health `/health` + `/alive` (4 APIs) | Implementado | ~95% |
| Despliegue Docker → Azure (ACA) | Documentado | Guía en `docs/despliegue/azure/` |
| Despliegue Docker → AWS (ECS) | Documentado | Guía en `docs/despliegue/aws/` |
| Kubernetes (Minikube / AKS / EKS) | Implementado | Manifiestos `k8s/` (5 APIs + Ingress) |
| Observabilidad / Resiliencia | Documentado | Azure + AWS separados |
| Integración IA + despliegue MCP | Documentado + código | `AI/`, `k8s/mcp/` |
| Spec-driven (Cursor + Claude Code) | Plantillas en `spec-driven/` | ~90% |
| Docker por servicio | Implementado | ~90% |

---

## 15. Observaciones técnicas

1. **Typo consistente:** los proyectos de infraestructura usan `Infraestructure` (con "e") en Catalog y Orders; Inventory usa `Infrastructure` (ortografía estándar).

2. **Validación en dos capas:** FluentValidation valida la forma del comando (Application); los Value Objects validan reglas de negocio (Domain). Separación correcta y deliberada.

3. **Stock en dos contextos:** Catalog tiene `StockLevel` (informativo en catálogo); Inventory tiene `StockEntry` (stock operativo para reservas). En el ejercicio, Inventory es la fuente de verdad para reservas.

4. **DTOs vs agregados:** ninguna API expone agregados directamente; siempre se proyectan a DTOs en Application.

5. **Referencias a Shared:** los proyectos Domain referencian `../../ShopDemo.Shared/ShopDemo.Shared.csproj` desde subcarpetas `Catalog/`, `Orders/`, `Inventory/`.

6. **Fase 1 Aspire:** Catalog, Orders e Inventory no usan `AddServiceDefaults()` en su `Program.cs`. Solo Analytics lo adopta; los tres microservicios existentes se referencian desde AppHost sin cambios en dominio ni application.

7. **Dos modos de stock inicial:** con Event Hubs habilitado, Inventory crea stock automáticamente al recibir `ProductCreated`. Sin Event Hubs, el ejercicio manual (`POST /api/inventory/stock`) sigue siendo válido.

8. **MCP fuera de Aspire:** el AppHost orquesta las 4 APIs de negocio; MCP se levanta aparte porque es un adaptador para agentes, no parte del dominio e-commerce.

9. **Manifiestos K8s unificados:** los mismos YAML en `k8s/` sirven para Minikube, AKS y EKS; solo cambian registry de imágenes y secretos.

---

## 16. Resumen ejecutivo

ShopDemo implementa **tres microservicios de negocio** que modelan un flujo de e-commerce — definición de productos (Catalog), gestión de pedidos (Orders) y control de stock (Inventory) — más un **observador** (Analytics) y un **MCP Gateway** para agentes IA. Catalog y Orders usan **Clean Architecture con CQRS**; Inventory usa **arquitectura hexagonal**.

La integración combina **HTTP síncrono** (Orders → Inventory), **Azure Event Hubs** con fan-out (`inventory-service` + `analytics-service`) y orquestación local vía **AppHost**. Cada servicio puede ejecutarse con **Docker Compose**, bajo **Aspire**, en **Kubernetes** (`k8s/`) o en **Azure Container Apps / AKS** y **AWS ECS / EKS**.

**Cómo levantar el sistema:** [README.md](../README.md#tabla-maestra-de-arranque) (tabla maestra) · [Inicio local](../README.md#inicio-local-desarrollo-y-pruebas) · [Release Azure](../README.md#release-azure) · [Release AWS](../README.md#release-aws)
