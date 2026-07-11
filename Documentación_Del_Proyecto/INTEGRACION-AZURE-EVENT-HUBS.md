# Integración de microservicios con Azure Event Hubs — Guía paso a paso (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Versión:** 2.1  
**Audiencia:** Alumnos que implementarán la integración desde cero siguiendo cada paso

> Esta guía incluye configuración en **Azure Portal**, **Azure CLI** y **activación mediante contenedores Docker** (`.env` + `docker-compose.yml`). El código está separado por microservicio (Catalog, Orders, Inventory).

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 5)  
**Código completo para copiar/integrar:** [ANEXO-CODIGO-EVENT-HUBS.md](./ANEXO-CODIGO-EVENT-HUBS.md) — publishers, consumidor, DI, appsettings, `.env` y `docker-compose`.  
**Contrato compartido:** [ANEXO-CODIGO-SHARED.md](./ANEXO-CODIGO-SHARED.md) (`IntegrationEventEnvelope.cs`)

---

## Índice

1. [¿Qué vamos a lograr?](#1-qué-vamos-a-lograr)
2. [Fundamentos: Event Hubs vs Service Bus](#2-fundamentos-event-hubs-vs-service-bus)
3. [Casos de uso de streaming a gran escala](#3-casos-de-uso-de-streaming-a-gran-escala)
4. [Crear recursos en Azure Portal](#4-crear-recursos-en-azure-portal)
5. [Crear recursos con Azure CLI](#5-crear-recursos-con-azure-cli)
6. [Activación con contenedores Docker](#6-activación-con-contenedores-docker)
7. [Paso 0 — Contrato compartido (ShopDemo.Shared)](#7-paso-0--contrato-compartido-shopdemoshared)
8. [Paso 1 — Catalog API (productor)](#8-paso-1--catalog-api-productor)
9. [Paso 2 — Orders API (productor)](#9-paso-2--orders-api-productor)
10. [Paso 3 — Inventory API (productor + consumidor)](#10-paso-3--inventory-api-productor--consumidor)
11. [Paso 4 — Probar el flujo completo en contenedores](#11-paso-4--probar-el-flujo-completo-en-contenedores)
12. [Integración con C# y .NET (resumen técnico)](#12-integración-con-c-y-net-resumen-técnico)
13. [Monitoreo y escalabilidad](#13-monitoreo-y-escalabilidad)
14. [Solución de problemas frecuentes](#14-solución-de-problemas-frecuentes)

---

## 1. ¿Qué vamos a lograr?

### Estado antes (sin Event Hubs)

```
Catalog  ──► LoggingDomainEventPublisher  ──► consola
Orders   ──► LoggingDomainEventPublisher  ──► consola
Inventory──► LoggingIntegrationEventPublisher ──► consola
```

### Estado después (con Event Hubs)

```
Catalog  ──► EventHubsDomainEventPublisher      ──┐
Orders   ──► EventHubsDomainEventPublisher      ──┼──► Azure Event Hubs
Inventory──► EventHubsIntegrationEventPublisher ──┘
                                                      │
                                                      ▼
                              Inventory: CatalogEventsProcessor
                              (auto-registra stock al crear producto)
```

**Regla de oro:** el dominio y los handlers **no cambian**. Solo se sustituye el adaptador de infraestructura y se agrega configuración.

| Servicio | Rol en Event Hubs | Archivo clave |
|---|---|---|
| **Catalog** | Productor | `EventHubsDomainEventPublisher.cs` |
| **Orders** | Productor | `EventHubsDomainEventPublisher.cs` |
| **Inventory** | Productor + Consumidor | `EventHubsIntegrationEventPublisher.cs` + `CatalogEventsProcessor.cs` |

---

## 2. Fundamentos: Event Hubs vs Service Bus

### ¿Qué es Event Hubs?

Un **log de eventos de alta capacidad** en Azure. Muchos productores escriben; muchos consumidores leen el mismo stream usando **consumer groups** independientes.

| Concepto | Significado |
|---|---|
| **Namespace** | Contenedor del servicio (ej. `shopdemo-eh-ns`) |
| **Event Hub** | Canal de eventos (ej. `shopdemo-events`) |
| **Partición** | División para paralelismo; eventos con la misma clave van a la misma partición |
| **Consumer Group** | Vista de lectura independiente (`inventory-service`) |
| **Checkpoint** | Posición de lectura guardada en Azure Blob Storage |

### Comparación con Azure Service Bus

| | Event Hubs | Service Bus |
|---|---|---|
| **Enfoque** | Streaming / ingesta masiva | Mensajería entre apps |
| **Volumen** | Muy alto (millones/seg) | Moderado |
| **Retención** | Stream consultable (replay) | Mensaje se consume y desaparece |
| **Dead-letter** | No nativo (lo implementas tú) | Sí, integrado |
| **Ideal en ShopDemo** | Notificar `ProductCreated` a varios servicios | Comandos con ACK estricto (futuro) |

**Para este curso usamos Event Hubs** porque el diagrama de arquitectura de ShopDemo define un **Message Bus** para Domain Events entre bounded contexts.

---

## 3. Casos de uso de streaming a gran escala

### En ShopDemo (implementado en esta guía)

| Evento | Emisor | Consumidor | Efecto |
|---|---|---|---|
| `ProductCreatedDomainEvent` | Catalog | Inventory (`CatalogEventsProcessor`) | Stock auto-registrado |
| `OrderPlacedDomainEvent` | Orders | (futuro) Analytics | Métricas en tiempo real |
| `StockReservedDomainEvent` | Inventory | (futuro) Dashboards | Rotación de inventario |

### Escenarios de gran escala (contexto industria)

- **Telemetría:** millones de eventos de APIs distribuidas.
- **IoT:** sensores enviando lecturas continuas.
- **Fan-out:** un evento alimenta inventario, notificaciones y BI sin que el emisor los conozca.
- **Replay:** un nuevo microservicio lee eventos históricos desde un offset.

---

## 4. Crear recursos en Azure Portal

Sigue estos pasos **en orden** si prefieres la interfaz gráfica.

### 4.1 Grupo de recursos

1. Inicia sesión en [https://portal.azure.com](https://portal.azure.com).
2. Busca **Resource groups** → **Create**.
3. Nombre: `rg-shopdemo`.
4. Región: la más cercana (ej. **Mexico Central**).
5. **Review + create** → **Create**.

### 4.2 Namespace de Event Hubs

1. **Create a resource** → busca **Event Hubs**.
2. Selecciona **Event Hubs** (Microsoft) → **Create**.
3. Configura:
   - **Subscription:** tu suscripción.
   - **Resource group:** `rg-shopdemo`.
   - **Namespace name:** `shopdemo-eh-ns` (debe ser único globalmente).
   - **Location:** misma región que el grupo.
   - **Pricing tier:** **Standard** (suficiente para el curso).
4. **Review + create** → **Create**.
5. Espera a que el despliegue termine → **Go to resource**.

### 4.3 Event Hub (canal de eventos)

1. Dentro del namespace `shopdemo-eh-ns`, menú izquierdo → **Event Hubs**.
2. **+ Event Hub**.
3. Nombre: `shopdemo-events`.
4. **Partition Count:** `4` (paralelismo para el curso).
5. **Message retention:** `1` día (Standard).
6. **Create**.

### 4.4 Obtener connection string del namespace

1. En el namespace, menú izquierdo → **Shared access policies**.
2. Clic en **RootManageSharedAccessKey**.
3. Copia **Primary Connection String**.
4. Guárdala de forma segura — la usarás en `EventHubs:ConnectionString` de las tres APIs.

> Formato esperado: `Endpoint=sb://shopdemo-eh-ns.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...`

### 4.5 Storage Account (checkpoints del consumidor de Inventory)

El consumidor de Inventory necesita Blob Storage para recordar qué eventos ya procesó.

1. **Create a resource** → **Storage account**.
2. Configura:
   - **Resource group:** `rg-shopdemo`.
   - **Storage account name:** `shopdemocheckpoints` (único, solo minúsculas y números).
   - **Performance:** Standard.
   - **Redundancy:** LRS.
3. **Review + create** → **Create**.
4. Ve al storage account → **Access keys**.
5. Copia **Connection string** de `key1`.

Esta cadena va en `EventHubs:CheckpointStorageConnectionString` de **Inventory** únicamente.

### 4.6 Verificar consumer group (opcional en Portal)

1. Namespace → **Event Hubs** → `shopdemo-events`.
2. Menú → **Consumer groups**.
3. Verás `$Default`. El código de Inventory crea/usará `inventory-service` automáticamente al iniciar el processor.

---

## 5. Crear recursos con Azure CLI

Alternativa equivalente para alumnos que prefieren terminal.

### 5.1 Prerrequisitos

```bash
az login
az account set --subscription "<TU-SUBSCRIPTION-ID>"
```

### 5.2 Crear todos los recursos

```bash
# Variables — personaliza si es necesario
RESOURCE_GROUP=rg-shopdemo
LOCATION=mexicocentral
NAMESPACE=shopdemo-eh-ns
EVENT_HUB=shopdemo-events
STORAGE_ACCOUNT=shopdemocheckpoints

# Grupo de recursos
az group create --name $RESOURCE_GROUP --location $LOCATION

# Namespace Event Hubs (SKU Standard)
az eventhubs namespace create \
  --resource-group $RESOURCE_GROUP \
  --name $NAMESPACE \
  --sku Standard \
  --location $LOCATION

# Event Hub con 4 particiones
az eventhubs eventhub create \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NAMESPACE \
  --name $EVENT_HUB \
  --partition-count 4 \
  --message-retention 1

# Storage para checkpoints
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Obtener connection strings
echo "=== Event Hubs Connection String ==="
az eventhubs namespace authorization-rule keys list \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NAMESPACE \
  --name RootManageSharedAccessKey \
  --query primaryConnectionString -o tsv

echo "=== Storage Connection String ==="
az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv
```

Copia ambas cadenas y guárdalas. **No las subas al repositorio.** Las configurarás en el archivo `.env` de cada API antes de levantar los contenedores (ver sección 6).

---

## 6. Activación con contenedores Docker

Esta es la forma **recomendada** en el curso para activar Event Hubs. Cada API lee la configuración desde variables de entorno inyectadas por **Docker Compose**.

### 6.1 Cómo funciona

```
.env (en carpeta de cada API)
        │
        ▼  Docker Compose sustituye ${VARIABLES}
docker-compose.yml
        │
        ▼  environment: EventHubs__Enabled, EventHubs__ConnectionString...
Contenedor de la API (.NET)
        │
        ▼  IConfiguration["EventHubs:Enabled"]
EventHubsDomainEventPublisher / CatalogEventsProcessor
```

ASP.NET Core mapea automáticamente `EventHubs__Enabled` → `EventHubs:Enabled` en configuración.

### 6.2 Variables de entorno por servicio

| Variable en `.env` | Mapeo en contenedor | Catalog | Orders | Inventory |
|---|---|---|---|---|
| `EVENT_HUBS_ENABLED` | `EventHubs__Enabled` | ✅ | ✅ | ✅ |
| `EVENT_HUBS_CONNECTION_STRING` | `EventHubs__ConnectionString` | ✅ | ✅ | ✅ |
| `EVENT_HUBS_NAME` | `EventHubs__EventHubName` | ✅ | ✅ | ✅ |
| `EVENT_HUBS_CONSUMER_GROUP` | `EventHubs__ConsumerGroup` | — | — | ✅ |
| `EVENT_HUBS_CHECKPOINT_STORAGE` | `EventHubs__CheckpointStorageConnectionString` | — | — | ✅ |
| `EVENT_HUBS_CHECKPOINT_CONTAINER` | `EventHubs__CheckpointContainerName` | — | — | ✅ |

### 6.3 Pasos comunes (todos los servicios)

**Paso 1** — En la carpeta de cada API, copia la plantilla de entorno:

```bash
# Catalog
cd Source/Catalog/ShopDemo.Catalog.Api
copy .env.example .env

# Orders
cd Source/Orders/ShopDemo.Orders.Api
copy .env.example .env

# Inventory
cd Source/Inventory/ShopDemo.Inventory.Api
copy .env.example .env
```

En Linux/macOS usa `cp .env.example .env`.

**Paso 2** — Edita cada `.env` con tus valores de Azure (sección 4 o 5):

```env
EVENT_HUBS_ENABLED=true
EVENT_HUBS_CONNECTION_STRING=Endpoint=sb://shopdemo-eh-ns.servicebus.windows.net/;SharedAccessKeyName=...
EVENT_HUBS_NAME=shopdemo-events
```

**Paso 3** — Inventory: el `docker-compose.yml` incluye **Azurite** (emulador de Blob Storage) para checkpoints. El `.env.example` ya trae la connection string hacia `http://azurite:10000`. Si prefieres Azure Storage real, reemplaza `EVENT_HUBS_CHECKPOINT_STORAGE` con la cadena del Portal.

> **Importante:** El archivo `.env` está en `.gitignore`. Nunca lo commitees.

### 6.4 Levantar Catalog en contenedor

**Archivo:** `Source/Catalog/ShopDemo.Catalog.Api/docker-compose.yml`

```yaml
  catalog-service:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Host=catalog-db;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
```

```bash
cd Source/Catalog/ShopDemo.Catalog.Api
docker compose up --build
```

API: `http://localhost:8001` | Swagger: `http://localhost:8001/swagger`

### 6.5 Levantar Orders en contenedor

**Archivo:** `Source/Orders/ShopDemo.Orders.Api/docker-compose.yml`

```yaml
  orders-service:
    environment:
      - ConnectionStrings__DefaultConnection=Host=orders-db;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123
      - InventoryApi__BaseUrl=http://host.docker.internal:8003
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
```

```bash
cd Source/Orders/ShopDemo.Orders.Api
docker compose up --build
```

API: `http://localhost:8002`

### 6.6 Levantar Inventory en contenedor (productor + consumidor + Azurite)

**Archivo:** `Source/Inventory/ShopDemo.Inventory.Api/docker-compose.yml`

Incluye tres servicios: PostgreSQL, **Azurite** (checkpoints) y la API con `CatalogEventsProcessor`.

```yaml
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    command: azurite-blob --blobHost 0.0.0.0 --blobPort 10000 --location /data

  inventory-service:
    environment:
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
      - EventHubs__ConsumerGroup=${EVENT_HUBS_CONSUMER_GROUP:-inventory-service}
      - EventHubs__CheckpointStorageConnectionString=${EVENT_HUBS_CHECKPOINT_STORAGE:-...azurite...}
      - EventHubs__CheckpointContainerName=${EVENT_HUBS_CHECKPOINT_CONTAINER:-inventory-checkpoints}
    depends_on:
      inventory-db:
        condition: service_healthy
      azurite:
        condition: service_started
```

```bash
cd Source/Inventory/ShopDemo.Inventory.Api
docker compose up --build
```

API: `http://localhost:8003` | Azurite Blob: `http://localhost:10000`

### 6.7 Orden de arranque con Event Hubs (contenedores)

Abre **tres terminales** o usa `-d` (detached):

```bash
# Terminal 1 — Inventory primero (consumidor debe estar listo)
cd Source/Inventory/ShopDemo.Inventory.Api
docker compose up --build

# Terminal 2 — Catalog (publica ProductCreated)
cd Source/Catalog/ShopDemo.Catalog.Api
docker compose up --build

# Terminal 3 — Orders (opcional)
cd Source/Orders/ShopDemo.Orders.Api
docker compose up --build
```

### 6.8 Verificar que Event Hubs está activo en el contenedor

```bash
docker logs shopdemo-catalog-api 2>&1 | findstr /i "Event Hubs"
docker logs shopdemo-inventory-api 2>&1 | findstr /i "consumer started"
```

En Linux/macOS usa `grep` en lugar de `findstr`.

Logs esperados:
- Catalog: `Catalog published ProductCreatedDomainEvent (...) to Event Hubs`
- Inventory: `Inventory Event Hubs consumer started`

### 6.9 Modo sin Event Hubs (solo logging)

Deja en cada `.env`:

```env
EVENT_HUBS_ENABLED=false
```

Los contenedores arrancan igual; los eventos solo aparecen en `docker logs`.

### 6.10 Alternativa local sin Docker

Si ejecutas con `dotnet run` fuera de contenedores, puedes usar **User Secrets** (opcional, no requerido para el curso con Docker):

```bash
dotnet user-secrets set "EventHubs:Enabled" "true"
dotnet user-secrets set "EventHubs:ConnectionString" "<CONNECTION-STRING>"
```

---

## 7. Paso 0 — Contrato compartido (ShopDemo.Shared)

**Objetivo:** Definir el formato JSON común que viaja por el bus.

**Archivo a crear:** `Source/ShopDemo.Shared/Messaging/IntegrationEventEnvelope.cs`

```csharp
namespace ShopDemo.Shared.Messaging;

/// <summary>
/// Formato común para transportar eventos entre microservicios vía Azure Event Hubs.
/// </summary>
public sealed record IntegrationEventEnvelope(
    string EventType,
    Guid EventId,
    DateTimeOffset OccurredOn,
    string Source,
    string PayloadJson);
```

**Explicación breve:**

- `EventType` — nombre del evento de dominio (ej. `ProductCreatedDomainEvent`).
- `Source` — microservicio emisor: `catalog`, `orders` o `inventory`.
- `PayloadJson` — evento serializado para que el consumidor lo deserialice.

**Verificación:** `dotnet build Source/ShopDemo.Shared/ShopDemo.Shared.csproj` sin errores.

---

## 8. Paso 1 — Catalog API (productor)

Catalog publica eventos cuando se crea un producto (`CreateProductHandler` → `IDomainEventPublisher`).

### 8.1 Instalar paquete NuGet

```bash
cd I:\Curso\ShopDemo

dotnet add Source/Catalog/ShopDemo.Catalog.Infraestructure/ShopDemo.Catalog.Infraestructure.csproj \
  package Azure.Messaging.EventHubs

dotnet add Source/Catalog/ShopDemo.Catalog.Infraestructure/ShopDemo.Catalog.Infraestructure.csproj \
  package Microsoft.Extensions.Configuration.Binder
```

### 8.2 Crear el publicador de Catalog

**Archivo:** `Source/Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs`

```csharp
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Catalog.Domain.Events;
using ShopDemo.Shared.Domain;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Catalog.Infraestructure.Messaging;

/// <summary>
/// Adaptador de Catalog: publica Domain Events al Event Hub de Azure.
/// Sustituye a LoggingDomainEventPublisher cuando EventHubs:Enabled = true.
/// </summary>
public sealed class EventHubsDomainEventPublisher : IDomainEventPublisher, IAsyncDisposable
{
    private readonly EventHubProducerClient _producer;
    private readonly ILogger<EventHubsDomainEventPublisher> _logger;

    public EventHubsDomainEventPublisher(
        IConfiguration configuration,
        ILogger<EventHubsDomainEventPublisher> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Catalog.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Catalog.");

        _producer = new EventHubProducerClient(connectionString, eventHubName);
        _logger = logger;
    }

    public async Task PublishAsync(
        IReadOnlyCollection<IDomainEvent> domainEvents,
        CancellationToken ct = default)
    {
        foreach (var domainEvent in domainEvents)
        {
            var envelope = new IntegrationEventEnvelope(
                EventType: domainEvent.GetType().Name,
                EventId: domainEvent.EventId,
                OccurredOn: domainEvent.OccurredOn,
                Source: "catalog",
                PayloadJson: JsonSerializer.Serialize(domainEvent, domainEvent.GetType()));

            var partitionKey = GetPartitionKey(domainEvent);
            var eventBody = new EventData(JsonSerializer.SerializeToUtf8Bytes(envelope));

            using var batch = await _producer.CreateBatchAsync(
                new CreateBatchOptions { PartitionKey = partitionKey }, ct);

            if (!batch.TryAdd(eventBody))
                throw new InvalidOperationException(
                    $"Catalog event '{envelope.EventType}' is too large for an Event Hubs batch.");

            await _producer.SendAsync(batch, ct);

            _logger.LogInformation(
                "Catalog published {EventType} ({EventId}) to Event Hubs",
                envelope.EventType,
                envelope.EventId);
        }
    }

    private static string GetPartitionKey(IDomainEvent domainEvent) => domainEvent switch
    {
        ProductCreatedDomainEvent e => e.ProductId.ToString(),
        ProductPriceChangedDomainEvent e => e.ProductId.ToString(),
        ProductDeactivatedDomainEvent e => e.ProductId.ToString(),
        StockReplenishedDomainEvent e => e.ProductId.ToString(),
        StockDepletedDomainEvent e => e.ProductId.ToString(),
        _ => domainEvent.EventId.ToString()
    };

    public async ValueTask DisposeAsync() => await _producer.DisposeAsync();
}
```

**Explicación breve:**

- Implementa `IDomainEventPublisher` — el handler de Catalog no se modifica.
- `Source: "catalog"` identifica el emisor en el bus.
- `PartitionKey` usa `ProductId` para mantener orden por producto.

### 8.3 Actualizar DependencyInjection de Catalog

**Archivo:** `Source/Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs`

Reemplaza el registro fijo de `LoggingDomainEventPublisher` por:

```csharp
if (configuration.GetValue<bool>("EventHubs:Enabled"))
    services.AddSingleton<IDomainEventPublisher, EventHubsDomainEventPublisher>();
else
    services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();
```

**Explicación:** Con `Enabled=false` (por defecto) sigues desarrollando sin Azure. Con `true` se usa Event Hubs.

### 8.4 Configurar appsettings y activar con Docker

**Archivo:** `Source/Catalog/ShopDemo.Catalog.Api/appsettings.json`

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5433;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123"
  },
  "EventHubs": {
    "Enabled": false,
    "ConnectionString": "",
    "EventHubName": "shopdemo-events"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

**Para activar Event Hubs en contenedor** — edita `Source/Catalog/ShopDemo.Catalog.Api/.env`:

```env
EVENT_HUBS_ENABLED=true
EVENT_HUBS_CONNECTION_STRING=Endpoint=sb://shopdemo-eh-ns.servicebus.windows.net/;SharedAccessKeyName=...
EVENT_HUBS_NAME=shopdemo-events
```

Luego levanta el servicio (ver [sección 6.4](#64-levantar-catalog-en-contenedor)):

```bash
cd Source/Catalog/ShopDemo.Catalog.Api
docker compose up --build
```

> Docker Compose lee `.env` automáticamente y sustituye `${EVENT_HUBS_*}` en `docker-compose.yml`.

### 8.5 Verificar Catalog en contenedor

```bash
docker compose -f Source/Catalog/ShopDemo.Catalog.Api/docker-compose.yml logs catalog-service
```

Con `EVENT_HUBS_ENABLED=true`, crea un producto:

```http
POST http://localhost:8001/api/products
Content-Type: application/json

{
  "name": "Teclado Mecánico",
  "description": "RGB",
  "price": 89.99,
  "currency": "USD",
  "stock": 50,
  "category": "Electronics"
}
```

En logs de Catalog debe aparecer: `Catalog published ProductCreatedDomainEvent (...) to Event Hubs`.

---

## 9. Paso 2 — Orders API (productor)

Orders publica eventos al crear, confirmar o cancelar pedidos.

### 9.1 Instalar paquete NuGet

```bash
dotnet add Source/Orders/ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj \
  package Azure.Messaging.EventHubs

dotnet add Source/Orders/ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj \
  package Microsoft.Extensions.Configuration.Binder
```

### 9.2 Crear el publicador de Orders

**Archivo:** `Source/Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs`

```csharp
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Events;
using ShopDemo.Shared.Domain;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Orders.Infraestructure.Messaging;

/// <summary>
/// Adaptador de Orders: publica Domain Events al Event Hub de Azure.
/// Sustituye a LoggingDomainEventPublisher cuando EventHubs:Enabled = true.
/// </summary>
public sealed class EventHubsDomainEventPublisher : IDomainEventPublisher, IAsyncDisposable
{
    private readonly EventHubProducerClient _producer;
    private readonly ILogger<EventHubsDomainEventPublisher> _logger;

    public EventHubsDomainEventPublisher(
        IConfiguration configuration,
        ILogger<EventHubsDomainEventPublisher> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Orders.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Orders.");

        _producer = new EventHubProducerClient(connectionString, eventHubName);
        _logger = logger;
    }

    public async Task PublishAsync(
        IReadOnlyCollection<IDomainEvent> domainEvents,
        CancellationToken ct = default)
    {
        foreach (var domainEvent in domainEvents)
        {
            var envelope = new IntegrationEventEnvelope(
                EventType: domainEvent.GetType().Name,
                EventId: domainEvent.EventId,
                OccurredOn: domainEvent.OccurredOn,
                Source: "orders",
                PayloadJson: JsonSerializer.Serialize(domainEvent, domainEvent.GetType()));

            var partitionKey = GetPartitionKey(domainEvent);
            var eventBody = new EventData(JsonSerializer.SerializeToUtf8Bytes(envelope));

            using var batch = await _producer.CreateBatchAsync(
                new CreateBatchOptions { PartitionKey = partitionKey }, ct);

            if (!batch.TryAdd(eventBody))
                throw new InvalidOperationException(
                    $"Orders event '{envelope.EventType}' is too large for an Event Hubs batch.");

            await _producer.SendAsync(batch, ct);

            _logger.LogInformation(
                "Orders published {EventType} ({EventId}) to Event Hubs",
                envelope.EventType,
                envelope.EventId);
        }
    }

    private static string GetPartitionKey(IDomainEvent domainEvent) => domainEvent switch
    {
        OrderPlacedDomainEvent e => e.OrderId.ToString(),
        OrderConfirmedDomainEvent e => e.OrderId.ToString(),
        OrderCancelledDomainEvent e => e.OrderId.ToString(),
        OrderShippedDomainEvent e => e.OrderId.ToString(),
        _ => domainEvent.EventId.ToString()
    };

    public async ValueTask DisposeAsync() => await _producer.DisposeAsync();
}
```

**Diferencia con Catalog:** `Source` es `"orders"` y la partition key usa `OrderId`.

### 9.3 Actualizar DependencyInjection de Orders

**Archivo:** `Source/Orders/ShopDemo.Orders.Infraestructure/DependencyInjection.cs`

```csharp
if (configuration.GetValue<bool>("EventHubs:Enabled"))
    services.AddSingleton<IDomainEventPublisher, EventHubsDomainEventPublisher>();
else
    services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();
```

### 9.4 Configurar appsettings y activar con Docker

**Archivo:** `Source/Orders/ShopDemo.Orders.Api/appsettings.json` — mantiene `EventHubs:Enabled: false` por defecto.

**Para activar en contenedor** — edita `Source/Orders/ShopDemo.Orders.Api/.env`:

```env
EVENT_HUBS_ENABLED=true
EVENT_HUBS_CONNECTION_STRING=Endpoint=sb://shopdemo-eh-ns.servicebus.windows.net/;SharedAccessKeyName=...
EVENT_HUBS_NAME=shopdemo-events
```

```bash
cd Source/Orders/ShopDemo.Orders.Api
docker compose up --build
```

Ver [sección 6.5](#65-levantar-orders-en-contenedor).

### 9.5 Verificar Orders en contenedor

```bash
docker logs shopdemo-orders-api 2>&1 | findstr /i "Event Hubs"
```

Tras crear y confirmar un pedido, en logs debe aparecer:

- `Orders published OrderPlacedDomainEvent (...) to Event Hubs`
- `Orders published OrderConfirmedDomainEvent (...) to Event Hubs`

> La reserva de stock sigue siendo **HTTP** hacia Inventory (`InventoryApi:BaseUrl`). Event Hubs es complementario para notificaciones asíncronas.

---

## 10. Paso 3 — Inventory API (productor + consumidor)

Inventory es el más completo: **publica** sus eventos de stock y **consume** eventos de Catalog.

### 10.1 Instalar paquetes NuGet

```bash
dotnet add Source/Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj \
  package Azure.Messaging.EventHubs

dotnet add Source/Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj \
  package Azure.Messaging.EventHubs.Processor

dotnet add Source/Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj \
  package Azure.Storage.Blobs

dotnet add Source/Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj \
  package Microsoft.Extensions.Configuration.Binder

dotnet add Source/Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj \
  package Microsoft.Extensions.Hosting.Abstractions
```

### 10.2 Crear el publicador de Inventory

**Archivo:** `Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs`

```csharp
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Events;
using ShopDemo.Shared.Domain;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Messaging;

/// <summary>
/// Adaptador driven de Inventory: publica eventos de integración al Event Hub de Azure.
/// Sustituye a LoggingIntegrationEventPublisher cuando EventHubs:Enabled = true.
/// </summary>
public sealed class EventHubsIntegrationEventPublisher : IIntegrationEventPublisher, IAsyncDisposable
{
    private readonly EventHubProducerClient _producer;
    private readonly ILogger<EventHubsIntegrationEventPublisher> _logger;

    public EventHubsIntegrationEventPublisher(
        IConfiguration configuration,
        ILogger<EventHubsIntegrationEventPublisher> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Inventory.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Inventory.");

        _producer = new EventHubProducerClient(connectionString, eventHubName);
        _logger = logger;
    }

    public async Task PublishAsync(
        IReadOnlyCollection<IDomainEvent> events,
        CancellationToken ct = default)
    {
        foreach (var domainEvent in events)
        {
            var envelope = new IntegrationEventEnvelope(
                EventType: domainEvent.GetType().Name,
                EventId: domainEvent.EventId,
                OccurredOn: domainEvent.OccurredOn,
                Source: "inventory",
                PayloadJson: JsonSerializer.Serialize(domainEvent, domainEvent.GetType()));

            var partitionKey = GetPartitionKey(domainEvent);
            var eventBody = new EventData(JsonSerializer.SerializeToUtf8Bytes(envelope));

            using var batch = await _producer.CreateBatchAsync(
                new CreateBatchOptions { PartitionKey = partitionKey }, ct);

            if (!batch.TryAdd(eventBody))
                throw new InvalidOperationException(
                    $"Inventory event '{envelope.EventType}' is too large for an Event Hubs batch.");

            await _producer.SendAsync(batch, ct);

            _logger.LogInformation(
                "Inventory published {EventType} ({EventId}) to Event Hubs",
                envelope.EventType,
                envelope.EventId);
        }
    }

    private static string GetPartitionKey(IDomainEvent domainEvent) => domainEvent switch
    {
        StockEntryRegisteredDomainEvent e => e.ProductId.ToString(),
        StockReservedDomainEvent e => e.ProductId.ToString(),
        StockReleasedDomainEvent e => e.ProductId.ToString(),
        StockDepletedDomainEvent e => e.ProductId.ToString(),
        _ => domainEvent.EventId.ToString()
    };

    public async ValueTask DisposeAsync() => await _producer.DisposeAsync();
}
```

**Explicación:** En arquitectura hexagonal, Inventory usa `IIntegrationEventPublisher` (no `IDomainEventPublisher`). El patrón de envío es el mismo; cambia el nombre del puerto y `Source: "inventory"`.

### 10.3 Crear el consumidor de Inventory

**Archivo:** `Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs`

Este `BackgroundService` escucha el bus y, cuando llega `ProductCreatedDomainEvent` de Catalog, llama a `IRegisterStockUseCase` automáticamente.

```csharp
using System.Text;
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Messaging;

/// <summary>
/// Consumidor de Inventory: escucha eventos de Catalog desde Event Hubs.
/// Auto-registra stock cuando llega ProductCreatedDomainEvent.
/// </summary>
public sealed class CatalogEventsProcessor : BackgroundService
{
    private readonly EventProcessorClient _processor;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<CatalogEventsProcessor> _logger;

    public CatalogEventsProcessor(
        IConfiguration configuration,
        IServiceScopeFactory scopeFactory,
        ILogger<CatalogEventsProcessor> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Inventory consumer.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Inventory consumer.");

        var checkpointConnection = configuration["EventHubs:CheckpointStorageConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:CheckpointStorageConnectionString is not configured for Inventory consumer.");

        var checkpointContainer = configuration["EventHubs:CheckpointContainerName"]
            ?? "inventory-checkpoints";

        var consumerGroup = configuration["EventHubs:ConsumerGroup"]
            ?? "inventory-service";

        _processor = new EventProcessorClient(
            new BlobContainerClient(checkpointConnection, checkpointContainer),
            consumerGroup,
            connectionString,
            eventHubName);

        _processor.ProcessEventAsync += OnProcessEventAsync;
        _processor.ProcessErrorAsync += OnProcessErrorAsync;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    private async Task OnProcessEventAsync(ProcessEventArgs args)
    {
        var body = Encoding.UTF8.GetString(args.Data.Body.ToArray());
        var envelope = JsonSerializer.Deserialize<IntegrationEventEnvelope>(body);

        if (envelope is null)
        {
            await args.UpdateCheckpointAsync(args.CancellationToken);
            return;
        }

        if (envelope.Source == "catalog"
            && envelope.EventType == "ProductCreatedDomainEvent")
        {
            var payload = JsonSerializer.Deserialize<ProductCreatedPayload>(envelope.PayloadJson);

            if (payload is not null)
            {
                using var scope = _scopeFactory.CreateScope();
                var registerStock = scope.ServiceProvider
                    .GetRequiredService<IRegisterStockUseCase>();

                await registerStock.ExecuteAsync(
                    new RegisterStockRequest(
                        payload.ProductId,
                        payload.Name,
                        payload.InitialStock),
                    args.CancellationToken);

                _logger.LogInformation(
                    "Inventory auto-registered stock for product {ProductId} from Event Hubs",
                    payload.ProductId);
            }
        }

        await args.UpdateCheckpointAsync(args.CancellationToken);
    }

    private Task OnProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(
            args.Exception,
            "Inventory Event Hubs processor error. Partition={PartitionId}, Operation={Operation}",
            args.PartitionId,
            args.Operation);

        return Task.CompletedTask;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Inventory Event Hubs consumer started");
        return _processor.StartProcessingAsync(stoppingToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
        _logger.LogInformation("Inventory Event Hubs consumer stopped");
    }

    private sealed record ProductCreatedPayload(
        Guid ProductId,
        string Name,
        decimal Price,
        string Currency,
        int InitialStock,
        string Category);
}
```

**Explicación breve:**

- `ConsumerGroup = inventory-service` — lectura independiente de otros consumidores.
- `CheckpointStorageConnectionString` — Blob donde se guarda el progreso.
- Solo procesa eventos con `Source == "catalog"` y `EventType == "ProductCreatedDomainEvent"`.
- Usa `IServiceScopeFactory` porque el processor es singleton y los use cases son scoped.

### 10.4 Actualizar DependencyInjection de Inventory

**Archivo:** `Source/Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs`

```csharp
if (configuration.GetValue<bool>("EventHubs:Enabled"))
{
    services.AddSingleton<IIntegrationEventPublisher, EventHubsIntegrationEventPublisher>();
    services.AddHostedService<CatalogEventsProcessor>();
}
else
{
    services.AddScoped<IIntegrationEventPublisher, LoggingIntegrationEventPublisher>();
}
```

### 10.5 Configurar appsettings y activar con Docker

**Archivo:** `Source/Inventory/ShopDemo.Inventory.Api/appsettings.json` — valores por defecto con `Enabled: false`.

**Para activar en contenedor** — edita `Source/Inventory/ShopDemo.Inventory.Api/.env`:

```env
EVENT_HUBS_ENABLED=true
EVENT_HUBS_CONNECTION_STRING=Endpoint=sb://shopdemo-eh-ns.servicebus.windows.net/;SharedAccessKeyName=...
EVENT_HUBS_NAME=shopdemo-events
EVENT_HUBS_CONSUMER_GROUP=inventory-service

# Azurite (incluido en docker-compose) — valor por defecto del .env.example
EVENT_HUBS_CHECKPOINT_STORAGE=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
EVENT_HUBS_CHECKPOINT_CONTAINER=inventory-checkpoints
```

```bash
cd Source/Inventory/ShopDemo.Inventory.Api
docker compose up --build
```

El compose levanta **tres** contenedores: `inventory-db`, `azurite` y `inventory-service`. Ver [sección 6.6](#66-levantar-inventory-en-contenedor-productor--consumidor--azurite).

> Si usas Azure Storage real en lugar de Azurite, reemplaza `EVENT_HUBS_CHECKPOINT_STORAGE` con la connection string del Portal (sección 4.5).

---

## 11. Paso 4 — Probar el flujo completo en contenedores

### 11.1 Orden de arranque

Sigue el orden de la [sección 6.7](#67-orden-de-arranque-con-event-hubs-contenedores):

1. **Inventory** (`docker compose up` en `Source/Inventory/ShopDemo.Inventory.Api`)
2. **Catalog** (`docker compose up` en `Source/Catalog/ShopDemo.Catalog.Api`)
3. **Orders** (opcional)

Asegúrate de que en los tres `.env` tengas `EVENT_HUBS_ENABLED=true` y la misma `EVENT_HUBS_CONNECTION_STRING`.

### 11.2 Prueba: auto-registro de stock vía eventos

**Paso A** — Crear producto en Catalog (publica a Event Hubs):

```http
POST http://localhost:8001/api/products
Content-Type: application/json

{
  "name": "Mouse Inalámbrico",
  "description": "Ergonómico",
  "price": 29.99,
  "currency": "USD",
  "stock": 100,
  "category": "Electronics"
}
```

Copia el `id` de la respuesta.

**Paso B** — Esperar unos segundos (el consumidor procesa de forma asíncrona).

**Paso C** — Consultar stock en Inventory **sin** llamar a `POST /api/inventory/stock`:

```http
GET http://localhost:8003/api/inventory/{productId}
```

**Resultado esperado:** `availableUnits: 100` registrado automáticamente por `CatalogEventsProcessor`.

### 11.3 Verificar en Azure Portal y contenedores

1. Namespace → **Metrics** → **Incoming Messages** (incrementa al crear producto).
2. `docker logs shopdemo-inventory-api` → contenedor `inventory-checkpoints` creado en Azurite.
3. `docker logs shopdemo-azurite` → operaciones blob si el consumidor guarda checkpoints.

### 11.4 Checklist del alumno

| # | Verificación |
|---|---|
| 1 | `.env` copiado desde `.env.example` en cada API |
| 2 | `EVENT_HUBS_ENABLED=false` → contenedores arrancan, eventos en `docker logs` |
| 3 | `EVENT_HUBS_ENABLED=true` → Catalog publica a Event Hubs |
| 4 | Inventory en contenedor → `Inventory Event Hubs consumer started` en logs |
| 5 | Crear producto → stock auto-creado sin `POST /api/inventory/stock` |
| 6 | Reiniciar contenedor Inventory → no reprocesa eventos viejos (checkpoint en Azurite) |

---

## 12. Integración con C# y .NET (resumen técnico)

### Paquetes por servicio

| Servicio | Paquetes |
|---|---|
| Catalog | `Azure.Messaging.EventHubs`, `Microsoft.Extensions.Configuration.Binder` |
| Orders | `Azure.Messaging.EventHubs`, `Microsoft.Extensions.Configuration.Binder` |
| Inventory | `Azure.Messaging.EventHubs`, `Azure.Messaging.EventHubs.Processor`, `Azure.Storage.Blobs`, `Microsoft.Extensions.Configuration.Binder`, `Microsoft.Extensions.Hosting.Abstractions` |

### Clases del SDK utilizadas

| Clase | Servicio | Rol |
|---|---|---|
| `EventHubProducerClient` | Catalog, Orders, Inventory | Enviar eventos |
| `CreateBatchOptions` | Los tres productores | Definir `PartitionKey` |
| `EventProcessorClient` | Inventory | Consumir eventos |
| `BlobContainerClient` | Inventory | Persistir checkpoints |

### Capas que NO se modifican

| Capa | ¿Cambia? |
|---|---|
| Domain (agregados, eventos) | No |
| Application (handlers, use cases) | No |
| API (controllers) | No |
| Infrastructure (adaptadores) | **Sí** |
| appsettings / user secrets | **Sí** |

---

## 13. Monitoreo y escalabilidad

### 13.1 Métricas en Azure Portal

| Métrica | Dónde verla | Qué indica |
|---|---|---|
| **Incoming Messages** | Namespace → Metrics | Eventos que entran al hub |
| **Outgoing Messages** | Namespace → Metrics | Eventos consumidos |
| **Throttled Requests** | Namespace → Metrics | Necesitas más throughput (TU) |
| **Server Errors** | Namespace → Metrics | Problemas del servicio |

**Crear alerta (Portal):**

1. Namespace → **Alerts** → **Create alert rule**.
2. Métrica: `Incoming Messages`.
3. Condición: menor que `1` durante 15 minutos (productores caídos).
4. Acción: enviar email al equipo.

### 13.2 Diagnostic Settings (logs detallados)

1. Namespace → **Diagnostic settings** → **Add diagnostic setting**.
2. Selecciona: `Archive to a storage account` y/o `Send to Log Analytics workspace`.
3. Categorías: `OperationalLogs`, `AuditLogs`.

### 13.3 Escalabilidad

| Necesidad | Acción |
|---|---|
| Más throughput de ingesta | Aumentar **Throughput Units (TU)** en Standard |
| Más paralelismo de consumo | Más particiones (definir al crear el hub) |
| Más instancias de Inventory | Varias réplicas comparten particiones vía `EventProcessorClient` |
| Retención más larga | Aumentar **Message retention** (máx. 7 días en Standard) |

### 13.4 Consumer groups adicionales (extensión)

Si en el futuro agregas un servicio de Analytics:

1. Crea consumer group `analytics-service` en Portal o deja que el SDK lo cree.
2. Implementa otro `BackgroundService` similar a `CatalogEventsProcessor`.
3. Cada grupo lee **todo** el stream con su propio offset.

---

## 14. Solución de problemas frecuentes

| Problema | Causa probable | Solución |
|---|---|---|
| `ConnectionString is not configured` | `.env` vacío o no copiado | `copy .env.example .env` y completar valores |
| Contenedor no lee variables | `.env` no está junto a `docker-compose.yml` | Colocar `.env` en carpeta `ShopDemo.*.Api` |
| Stock no se auto-registra | `EVENT_HUBS_ENABLED=false` en Inventory | Verificar `.env` y `docker logs shopdemo-inventory-api` |
| Error de checkpoint | Azurite no arrancó | `docker ps` debe mostrar `shopdemo-azurite` |
| Quiero Azure pero sigue en log | `EVENT_HUBS_ENABLED=false` | Cambiar a `true` y `docker compose up --build` |
| Eventos duplicados | Reproceso tras fallo | `RegisterStock` tolera reabastecimiento (idempotencia parcial) |
| Build error en `TryAdd` | SDK antiguo | Usar `Azure.Messaging.EventHubs` 5.12.x |

---

## Referencias

- [Documentación Azure Event Hubs](https://learn.microsoft.com/azure/event-hubs/)
- [Event Hubs para .NET](https://learn.microsoft.com/azure/event-hubs/event-hubs-dotnet-standard-getstarted-send)
- [EventProcessorClient](https://learn.microsoft.com/azure/event-hubs/event-processor-balance-partition-load)
- [GUIA-ENDPOINTS.md](./GUIA-ENDPOINTS.md) — flujos HTTP de las APIs
- [ARQUITECTURA.md](./ARQUITECTURA.md) — visión global del sistema

---

## Resumen para el alumno

1. Crea recursos en **Azure Portal** o con **Azure CLI** (namespace, hub; storage opcional si usas Azurite).
2. Agrega `IntegrationEventEnvelope` en **Shared**.
3. Implementa publicador en **Catalog**, **Orders** e **Inventory** (código en cada servicio).
4. En cada API: `copy .env.example .env` y completa `EVENT_HUBS_*`.
5. Levanta contenedores: **Inventory** → **Catalog** → **Orders** con `docker compose up --build`.
6. Prueba: crear producto en `:8001` → stock aparece en `:8003` sin POST manual.
7. Monitorea métricas en Azure Portal y logs con `docker logs`.

La integración HTTP Orders → Inventory **se mantiene** para reservas síncronas. Event Hubs **complementa** con comunicación asíncrona entre bounded contexts.
