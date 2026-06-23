# Anexo — Código completo Event Hubs (copiar/integrar)

> Etapa 5. Requiere namespace y hubs creados en Azure (ver INTEGRACION-AZURE-EVENT-HUBS.md).

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 5)  
**Portal/CLI Azure:** [INTEGRACION-AZURE-EVENT-HUBS.md](./INTEGRACION-AZURE-EVENT-HUBS.md)

---
## `Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs`

**Para qué sirve:** Productor: serializa domain events de Catalog al hub `catalog-events`.

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

---
## `Catalog/ShopDemo.Catalog.Infraestructure/Messaging/LoggingDomainEventPublisher.cs`

**Para qué sirve:** Código de integración Event Hubs.

```csharp
using Microsoft.Extensions.Logging;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure.Messaging;

/// <summary>
/// Implementación de desarrollo que registra eventos en logs.
/// Sustituir por Event Hubs u otro broker en producción.
/// </summary>
public sealed class LoggingDomainEventPublisher(ILogger<LoggingDomainEventPublisher> logger)
    : IDomainEventPublisher
{
    public Task PublishAsync(
        IReadOnlyCollection<IDomainEvent> domainEvents,
        CancellationToken ct = default)
    {
        foreach (var domainEvent in domainEvents)
        {
            logger.LogInformation(
                "Domain event published: {EventType} ({EventId}) at {OccurredOn}",
                domainEvent.GetType().Name,
                domainEvent.EventId,
                domainEvent.OccurredOn);
        }

        return Task.CompletedTask;
    }
}
```

---
## `Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs`

**Para qué sirve:** Registra publisher según `EventHubs:Enabled` (logging vs Event Hubs).

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Catalog.Domain.Repositories;
using ShopDemo.Catalog.Infraestructure.Messaging;
using ShopDemo.Catalog.Infraestructure.Persistence;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure;

public static class DependencyInjection
{
    public static IServiceCollection AddCatalogInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<CatalogDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        if (configuration.GetValue<bool>("EventHubs:Enabled"))
            services.AddSingleton<IDomainEventPublisher, EventHubsDomainEventPublisher>();
        else
            services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();

        return services;
    }
}
```

---
## `Orders/ShopDemo.Orders.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs`

**Para qué sirve:** Productor: publica eventos de pedidos al hub `orders-events`.

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

---
## `Orders/ShopDemo.Orders.Infraestructure/Messaging/LoggingDomainEventPublisher.cs`

**Para qué sirve:** Código de integración Event Hubs.

```csharp
using Microsoft.Extensions.Logging;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Infraestructure.Messaging;

public sealed class LoggingDomainEventPublisher(ILogger<LoggingDomainEventPublisher> logger)
    : IDomainEventPublisher
{
    public Task PublishAsync(
        IReadOnlyCollection<IDomainEvent> domainEvents,
        CancellationToken ct = default)
    {
        foreach (var domainEvent in domainEvents)
        {
            logger.LogInformation(
                "Domain event published: {EventType} ({EventId}) at {OccurredOn}",
                domainEvent.GetType().Name,
                domainEvent.EventId,
                domainEvent.OccurredOn);
        }

        return Task.CompletedTask;
    }
}
```

---
## `Orders/ShopDemo.Orders.Infraestructure/DependencyInjection.cs`

**Para qué sirve:** Igual que Catalog para Orders.

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Infraestructure.Integrations;
using ShopDemo.Orders.Infraestructure.Messaging;
using ShopDemo.Orders.Infraestructure.Persistence;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Infraestructure;

public static class DependencyInjection
{
    public static IServiceCollection AddOrdersInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<OrdersDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        if (configuration.GetValue<bool>("EventHubs:Enabled"))
            services.AddSingleton<IDomainEventPublisher, EventHubsDomainEventPublisher>();
        else
            services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();

        var inventoryBaseUrl = configuration["InventoryApi:BaseUrl"]
            ?? "http://localhost:8003";

        services.AddHttpClient<IInventoryService, InventoryHttpClient>(client =>
        {
            client.BaseAddress = new Uri(inventoryBaseUrl.TrimEnd('/') + "/");
        });

        return services;
    }
}
```

---
## `Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs`

**Para qué sirve:** Productor: publica eventos de inventario al hub `inventory-events`.

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

---
## `Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs`

**Para qué sirve:** Consumidor: crea stock automático al recibir `ProductCreated` de Catalog.

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
/// Ejemplo del curso: auto-registra stock cuando llega ProductCreatedDomainEvent.
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

---
## `Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/LoggingIntegrationEventPublisher.cs`

**Para qué sirve:** Código de integración Event Hubs.

```csharp
using Microsoft.Extensions.Logging;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Messaging;

/// <summary>
/// Adaptador driven: publica eventos al log (sustituible por Event Hubs).
/// </summary>
public sealed class LoggingIntegrationEventPublisher(ILogger<LoggingIntegrationEventPublisher> logger)
    : IIntegrationEventPublisher
{
    public Task PublishAsync(IReadOnlyCollection<IDomainEvent> events, CancellationToken ct = default)
    {
        foreach (var domainEvent in events)
        {
            logger.LogInformation(
                "Integration event: {EventType} ({EventId}) at {OccurredOn}",
                domainEvent.GetType().Name,
                domainEvent.EventId,
                domainEvent.OccurredOn);
        }

        return Task.CompletedTask;
    }
}
```

---
## `Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs`

**Para qué sirve:** Publisher + `CatalogEventsProcessor` como hosted service.

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Application.UseCases;
using ShopDemo.Inventory.Infrastructure.Adapters.Messaging;
using ShopDemo.Inventory.Infrastructure.Adapters.Persistence;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInventoryInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<InventoryDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IStockEntryRepository, StockEntryRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        if (configuration.GetValue<bool>("EventHubs:Enabled"))
        {
            services.AddSingleton<IIntegrationEventPublisher, EventHubsIntegrationEventPublisher>();
            services.AddHostedService<CatalogEventsProcessor>();
        }
        else
        {
            services.AddScoped<IIntegrationEventPublisher, LoggingIntegrationEventPublisher>();
        }

        // Use Cases como implementaciones de Inbound Ports (hexagonal)
        services.AddScoped<IRegisterStockUseCase, RegisterStockUseCase>();
        services.AddScoped<IGetStockByProductUseCase, GetStockByProductUseCase>();
        services.AddScoped<IReserveStockUseCase, ReserveStockUseCase>();
        services.AddScoped<IReleaseStockUseCase, ReleaseStockUseCase>();

        return services;
    }
}
```

---
## `ShopDemo.Shared/Messaging/IntegrationEventEnvelope.cs`

**Para qué sirve:** Contrato JSON compartido entre productores y consumidores.

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

---
## `Catalog/ShopDemo.Catalog.Api/appsettings.json`

**Para qué sirve:** Configuración Event Hubs de Catalog (Enabled false por defecto).

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

---
## `Orders/ShopDemo.Orders.Api/appsettings.json`

**Para qué sirve:** Configuración Event Hubs de Orders.

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5434;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123"
  },
  "InventoryApi": {
    "BaseUrl": "http://localhost:8003"
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

---
## `Inventory/ShopDemo.Inventory.Api/appsettings.json`

**Para qué sirve:** Configuración Event Hubs + consumer group de Inventory.

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5435;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123"
  },
  "EventHubs": {
    "Enabled": false,
    "ConnectionString": "",
    "EventHubName": "shopdemo-events",
    "ConsumerGroup": "inventory-service",
    "CheckpointStorageConnectionString": "",
    "CheckpointContainerName": "inventory-checkpoints"
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

---
## `Catalog/ShopDemo.Catalog.Api/.env.example`

**Para qué sirve:** Plantilla Docker: variables `EventHubs__*` para Catalog.

```example
# Copiar este archivo a .env y completar con tus valores de Azure.
#   copy .env.example .env        (Windows)
#   cp .env.example .env          (Linux/macOS)
#
# NO commitear el archivo .env (contiene secretos).

# false = eventos solo en log | true = publicar a Azure Event Hubs
EVENT_HUBS_ENABLED=false

# Connection string del namespace (Portal → Shared access policies → RootManageSharedAccessKey)
EVENT_HUBS_CONNECTION_STRING=

# Nombre del Event Hub creado en Azure
EVENT_HUBS_NAME=shopdemo-events
```

---
## `Orders/ShopDemo.Orders.Api/.env.example`

**Para qué sirve:** Plantilla Docker: variables Event Hubs para Orders.

```example
# Copiar este archivo a .env y completar con tus valores de Azure.
#   copy .env.example .env        (Windows)
#   cp .env.example .env          (Linux/macOS)
#
# NO commitear el archivo .env (contiene secretos).

EVENT_HUBS_ENABLED=false
EVENT_HUBS_CONNECTION_STRING=
EVENT_HUBS_NAME=shopdemo-events
```

---
## `Inventory/ShopDemo.Inventory.Api/.env.example`

**Para qué sirve:** Plantilla Docker: variables Event Hubs para Inventory.

```example
# Copiar este archivo a .env y completar con tus valores de Azure.
#   copy .env.example .env        (Windows)
#   cp .env.example .env          (Linux/macOS)
#
# NO commitear el archivo .env (contiene secretos).

# --- Event Hubs (publicar y consumir) ---
EVENT_HUBS_ENABLED=false
EVENT_HUBS_CONNECTION_STRING=
EVENT_HUBS_NAME=shopdemo-events
EVENT_HUBS_CONSUMER_GROUP=inventory-service

# --- Checkpoints del consumidor ---
# Opción A: Azure Storage (producción / Azure Portal → Access keys)
# EVENT_HUBS_CHECKPOINT_STORAGE=DefaultEndpointsProtocol=https;AccountName=...

# Opción B: Azurite (incluido en docker-compose de Inventory — valor por defecto)
EVENT_HUBS_CHECKPOINT_STORAGE=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
EVENT_HUBS_CHECKPOINT_CONTAINER=inventory-checkpoints
```

---
## `Catalog/ShopDemo.Catalog.Api/docker-compose.yml`

**Para qué sirve:** Compose Catalog: inyecta `EventHubs__*` al contenedor API.

```yml
﻿services:
  catalog-db:
    image: postgres:16-alpine
    container_name: shopdemo-catalog-db
    environment:
      POSTGRES_DB: ShopDemoCatalog
      POSTGRES_USER: ShopDemo
      POSTGRES_PASSWORD: ShopDemo123
    ports:
      # Puerto 5433 en el host para no colisionar con PostgreSQL local (5432)
      - "5433:5432"
    volumes:
      - catalog-db-data:/var/lib/postgresql/data
      - ./docker/postgres/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ShopDemo -d ShopDemoCatalog"]
      interval: 5s
      timeout: 5s
      retries: 5

  catalog-service:
    build:
      context: ..
      dockerfile: ShopDemo.Catalog.Api/Dockerfile
    container_name: shopdemo-catalog-api
    ports:
      - "8001:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Host=catalog-db;Port=5432;Database=ShopDemoCatalog;Username=ShopDemo;Password=ShopDemo123
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
    depends_on:
      catalog-db:
        condition: service_healthy

volumes:
  catalog-db-data:
```

---
## `Orders/ShopDemo.Orders.Api/docker-compose.yml`

**Para qué sirve:** Compose Orders: variables Event Hubs + InventoryApi.

```yml
services:
  orders-db:
    image: postgres:16-alpine
    container_name: shopdemo-orders-db
    environment:
      POSTGRES_DB: ShopDemoOrders
      POSTGRES_USER: ShopDemo
      POSTGRES_PASSWORD: ShopDemo123
    ports:
      - "5434:5432"
    volumes:
      - orders-db-data:/var/lib/postgresql/data
      - ./docker/postgres/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ShopDemo -d ShopDemoOrders"]
      interval: 5s
      timeout: 5s
      retries: 5

  orders-service:
    build:
      context: ..
      dockerfile: ShopDemo.Orders.Api/Dockerfile
    container_name: shopdemo-orders-api
    ports:
      - "8002:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Host=orders-db;Port=5432;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123
      - InventoryApi__BaseUrl=http://host.docker.internal:8003
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
    depends_on:
      orders-db:
        condition: service_healthy

volumes:
  orders-db-data:
```

---
## `Inventory/ShopDemo.Inventory.Api/docker-compose.yml`

**Para qué sirve:** Compose Inventory: Event Hubs + Azurite para checkpoints.

```yml
services:
  inventory-db:
    image: postgres:16-alpine
    container_name: shopdemo-inventory-db
    environment:
      POSTGRES_DB: ShopDemoInventory
      POSTGRES_USER: ShopDemo
      POSTGRES_PASSWORD: ShopDemo123
    ports:
      - "5435:5432"
    volumes:
      - inventory-db-data:/var/lib/postgresql/data
      - ./docker/postgres/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ShopDemo -d ShopDemoInventory"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Emulador de Azure Blob Storage para checkpoints del consumidor Event Hubs
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    container_name: shopdemo-azurite
    ports:
      - "10000:10000"
    volumes:
      - azurite-data:/data
    command: azurite-blob --blobHost 0.0.0.0 --blobPort 10000 --location /data

  inventory-service:
    build:
      context: ../..
      dockerfile: Inventory/ShopDemo.Inventory.Api/Dockerfile
    container_name: shopdemo-inventory-api
    ports:
      - "8003:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Host=inventory-db;Port=5432;Database=ShopDemoInventory;Username=ShopDemo;Password=ShopDemo123
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
      - EventHubs__ConsumerGroup=${EVENT_HUBS_CONSUMER_GROUP:-inventory-service}
      - EventHubs__CheckpointStorageConnectionString=${EVENT_HUBS_CHECKPOINT_STORAGE:-DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;}
      - EventHubs__CheckpointContainerName=${EVENT_HUBS_CHECKPOINT_CONTAINER:-inventory-checkpoints}
    depends_on:
      inventory-db:
        condition: service_healthy
      azurite:
        condition: service_started

volumes:
  inventory-db-data:
  azurite-data:
```
