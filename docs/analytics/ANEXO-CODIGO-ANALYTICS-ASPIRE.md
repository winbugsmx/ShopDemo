# Anexo — Código completo Analytics + Aspire (copiar/integrar)

> Etapa 6. Copia en `Aspire/`. AppHost solo para desarrollo local.

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 6)  
**Explicación:** [IMPLEMENTACION-ANALYTICS-ASPIRE.md](./IMPLEMENTACION-ANALYTICS-ASPIRE.md)

---
## `Aspire/ShopDemo.Analytics.Api/Controllers/AnalyticsController.cs`

**Para qué sirve:** GET /api/analytics/events — lista eventos capturados.

```csharp
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Analytics.Api.Services;

namespace ShopDemo.Analytics.Api.Controllers;

[ApiController]
[Route("api/analytics")]
public sealed class AnalyticsController(InMemoryEventStore eventStore) : ControllerBase
{
    [HttpGet("events")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetEvents([FromQuery] int take = 50)
    {
        var events = eventStore.GetLatest(Math.Clamp(take, 1, 100));
        return Ok(new
        {
            totalBuffered = eventStore.Count,
            returned = events.Count,
            events
        });
    }

    [HttpGet("health")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetHealth() => Ok(new
    {
        service = "ShopDemo.Analytics.Api",
        status = "running",
        bufferedEvents = eventStore.Count
    });
}
```

---
## `Aspire/ShopDemo.Analytics.Api/Messaging/EventHubAnalyticsProcessor.cs`

**Para qué sirve:** Consumidor read-only: persiste eventos en memoria para consulta.

```csharp
using System.Text;
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using ShopDemo.Analytics.Api.Services;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Analytics.Api.Messaging;

/// <summary>
/// Consumidor de Analytics: observa todos los eventos del bus (consumer group analytics-service).
/// No ejecuta lógica de negocio — solo registra eventos para consulta.
/// </summary>
public sealed class EventHubAnalyticsProcessor : BackgroundService
{
    private readonly EventProcessorClient _processor;
    private readonly InMemoryEventStore _eventStore;
    private readonly ILogger<EventHubAnalyticsProcessor> _logger;

    public EventHubAnalyticsProcessor(
        IConfiguration configuration,
        InMemoryEventStore eventStore,
        ILogger<EventHubAnalyticsProcessor> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Analytics.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Analytics.");

        var checkpointConnection = configuration["EventHubs:CheckpointStorageConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:CheckpointStorageConnectionString is not configured for Analytics.");

        var checkpointContainer = configuration["EventHubs:CheckpointContainerName"]
            ?? "analytics-checkpoints";

        var consumerGroup = configuration["EventHubs:ConsumerGroup"]
            ?? "analytics-service";

        _processor = new EventProcessorClient(
            new BlobContainerClient(checkpointConnection, checkpointContainer),
            consumerGroup,
            connectionString,
            eventHubName);

        _processor.ProcessEventAsync += OnProcessEventAsync;
        _processor.ProcessErrorAsync += OnProcessErrorAsync;
        _eventStore = eventStore;
        _logger = logger;
    }

    private async Task OnProcessEventAsync(ProcessEventArgs args)
    {
        var body = Encoding.UTF8.GetString(args.Data.Body.ToArray());
        var envelope = JsonSerializer.Deserialize<IntegrationEventEnvelope>(body);

        if (envelope is not null)
        {
            _eventStore.Add(new StoredEvent(
                envelope.EventType,
                envelope.EventId,
                envelope.OccurredOn,
                envelope.Source,
                envelope.PayloadJson,
                DateTimeOffset.UtcNow));

            _logger.LogInformation(
                "Analytics observed {EventType} from {Source} ({EventId})",
                envelope.EventType,
                envelope.Source,
                envelope.EventId);
        }

        await args.UpdateCheckpointAsync(args.CancellationToken);
    }

    private Task OnProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(
            args.Exception,
            "Analytics Event Hubs processor error. Partition={PartitionId}",
            args.PartitionId);

        return Task.CompletedTask;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Analytics Event Hubs consumer started (group: analytics-service)");
        return _processor.StartProcessingAsync(stoppingToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
        _logger.LogInformation("Analytics Event Hubs consumer stopped");
    }
}
```

---
## `Aspire/ShopDemo.Analytics.Api/Program.cs`

**Para qué sirve:** Archivo de referencia — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.OpenApi;
using ShopDemo.Analytics.Api.Messaging;
using ShopDemo.Analytics.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ShopDemo Analytics API",
        Version = "v1",
        Description = "Observador de eventos del bus — orquestado por .NET Aspire"
    });
});

builder.Services.AddSingleton<InMemoryEventStore>();
builder.Services.AddHostedService<EventHubAnalyticsProcessor>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(o =>
    {
        o.SwaggerEndpoint("/swagger/v1/swagger.json", "ShopDemo Analytics API v1");
        o.RoutePrefix = "swagger";
    });
}

app.MapDefaultEndpoints();
app.MapControllers();

app.Run();
```

---
## `Aspire/ShopDemo.Analytics.Api/Services/InMemoryEventStore.cs`

**Para qué sirve:** Archivo de referencia — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Analytics.Api.Services;

/// <summary>
/// Almacén en memoria de los últimos eventos observados (ring buffer).
/// </summary>
public sealed class InMemoryEventStore
{
    private readonly object _lock = new();
    private readonly Queue<StoredEvent> _events = new();
    private const int MaxEvents = 100;

    public void Add(StoredEvent storedEvent)
    {
        lock (_lock)
        {
            _events.Enqueue(storedEvent);
            while (_events.Count > MaxEvents)
                _events.Dequeue();
        }
    }

    public IReadOnlyList<StoredEvent> GetLatest(int take = 50)
    {
        lock (_lock)
        {
            return _events.Reverse().Take(take).ToList();
        }
    }

    public int Count
    {
        get
        {
            lock (_lock)
                return _events.Count;
        }
    }
}

public sealed record StoredEvent(
    string EventType,
    Guid EventId,
    DateTimeOffset OccurredOn,
    string Source,
    string PayloadJson,
    DateTimeOffset ReceivedAt);
```

---
## `Aspire/ShopDemo.AppHost/Program.cs`

**Para qué sirve:** Orquesta 4 APIs + PostgreSQL + Azurite + config Event Hubs.

```csharp
using Aspire.Hosting.Azure;

var builder = DistributedApplication.CreateBuilder(args);

// ── Configuración Event Hubs (desde appsettings / user secrets del AppHost) ──
var eventHubsSection = builder.Configuration.GetSection("ShopDemo:EventHubs");
var eventHubsEnabled = eventHubsSection["Enabled"] ?? "true";
var eventHubsConnection = eventHubsSection["ConnectionString"]
    ?? throw new InvalidOperationException(
        "Configure ShopDemo:EventHubs:ConnectionString in AppHost appsettings or user secrets.");
var eventHubName = eventHubsSection["EventHubName"] ?? "shopdemo-events";

// ── PostgreSQL (un servidor, tres bases de datos) ──
var postgres = builder.AddPostgres("postgres")
    .WithDataVolume()
    .WithPgAdmin();

var catalogDb = postgres.AddDatabase("ShopDemoCatalog");
var ordersDb = postgres.AddDatabase("ShopDemoOrders");
var inventoryDb = postgres.AddDatabase("ShopDemoInventory");

// ── Azurite vía Aspire (checkpoints Event Hubs para Inventory y Analytics) ──
var storage = builder.AddAzureStorage("storage")
    .RunAsEmulator(emulator => emulator.WithDataVolume());

var blobs = storage.AddBlobs("blobs");

// Connection string del emulador para checkpoints
const string azuriteBlobConnection =
    "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;" +
    "AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;" +
    "BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;";

// ── Microservicios existentes (sin modificar Program.cs) ──
var catalog = builder.AddProject<Projects.ShopDemo_Catalog_Api>("catalog")
    .WithReference(catalogDb)
    .WithHttpEndpoint(port: 8001, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName);

var inventory = builder.AddProject<Projects.ShopDemo_Inventory_Api>("inventory")
    .WithReference(inventoryDb)
    .WithReference(blobs)
    .WithHttpEndpoint(port: 8003, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName)
    .WithEnvironment("EventHubs__ConsumerGroup", "inventory-service")
    .WithEnvironment("EventHubs__CheckpointStorageConnectionString", azuriteBlobConnection)
    .WithEnvironment("EventHubs__CheckpointContainerName", "inventory-checkpoints");

var orders = builder.AddProject<Projects.ShopDemo_Orders_Api>("orders")
    .WithReference(ordersDb)
    .WithReference(inventory)
    .WithHttpEndpoint(port: 8002, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName)
    .WithEnvironment("InventoryApi__BaseUrl", inventory.GetEndpoint("http"));

// ── Nuevo: Analytics (observador del bus) ──
builder.AddProject<Projects.ShopDemo_Analytics_Api>("analytics")
    .WithReference(blobs)
    .WithHttpEndpoint(port: 8004, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName)
    .WithEnvironment("EventHubs__ConsumerGroup", "analytics-service")
    .WithEnvironment("EventHubs__CheckpointStorageConnectionString", azuriteBlobConnection)
    .WithEnvironment("EventHubs__CheckpointContainerName", "analytics-checkpoints")
    .WaitFor(inventory);

builder.Build().Run();
```

---
## `Aspire/ShopDemo.ServiceDefaults/Extensions.cs`

**Para qué sirve:** Health checks, OpenTelemetry y resiliencia HTTP compartida.

```csharp
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

namespace Microsoft.Extensions.Hosting;

public static class Extensions
{
    public static IHostApplicationBuilder AddServiceDefaults(this IHostApplicationBuilder builder)
    {
        builder.ConfigureOpenTelemetry();
        builder.AddDefaultHealthChecks();
        builder.Services.AddServiceDiscovery();
        builder.Services.ConfigureHttpClientDefaults(http =>
        {
            http.AddStandardResilienceHandler();
            http.AddServiceDiscovery();
        });
        return builder;
    }

    public static IHostApplicationBuilder ConfigureOpenTelemetry(this IHostApplicationBuilder builder)
    {
        builder.Logging.AddOpenTelemetry(logging =>
        {
            logging.IncludeFormattedMessage = true;
            logging.IncludeScopes = true;
        });

        builder.Services.AddOpenTelemetry()
            .WithMetrics(metrics =>
            {
                metrics.AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation()
                    .AddRuntimeInstrumentation();
            })
            .WithTracing(tracing =>
            {
                tracing.AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation();
            });

        builder.AddOpenTelemetryExporters();
        return builder;
    }

    private static IHostApplicationBuilder AddOpenTelemetryExporters(this IHostApplicationBuilder builder)
    {
        var useOtlp = !string.IsNullOrWhiteSpace(builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]);
        if (useOtlp)
            builder.Services.AddOpenTelemetry().UseOtlpExporter();

        return builder;
    }

    public static IHostApplicationBuilder AddDefaultHealthChecks(this IHostApplicationBuilder builder)
    {
        builder.Services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy(), ["live"]);
        return builder;
    }

    public static WebApplication MapDefaultEndpoints(this WebApplication app)
    {
        app.MapHealthChecks("/health");
        app.MapHealthChecks("/alive", new HealthCheckOptions
        {
            Predicate = r => r.Tags.Contains("live")
        });

        return app;
    }
}
```

---
## `Aspire/ShopDemo.Analytics.Api/appsettings.json`

**Para qué sirve:** Configuración del consumidor Analytics (Event Hubs + store en memoria).

```json
{
  "EventHubs": {
    "Enabled": true,
    "ConnectionString": "",
    "EventHubName": "shopdemo-events",
    "ConsumerGroup": "analytics-service",
    "CheckpointStorageConnectionString": "",
    "CheckpointContainerName": "analytics-checkpoints"
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
## `Aspire/ShopDemo.Analytics.Api/.env.example`

**Para qué sirve:** Plantilla Docker para Analytics con variables Event Hubs.

```example
# Copiar a .env y completar valores.
#   copy .env.example .env        (Windows)
#   cp .env.example .env          (Linux/macOS)

EVENT_HUBS_ENABLED=false
EVENT_HUBS_CONNECTION_STRING=
EVENT_HUBS_NAME=shopdemo-events
EVENT_HUBS_CONSUMER_GROUP=analytics-service
EVENT_HUBS_CHECKPOINT_CONTAINER=analytics-checkpoints
```

---
## `Aspire/ShopDemo.Analytics.Api/docker-compose.yml`

**Para qué sirve:** Compose Analytics: puerto 8004 y variables del bus.

```yml
services:
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    container_name: shopdemo-analytics-azurite
    ports:
      - "10001:10000"
    volumes:
      - analytics-azurite-data:/data
    command: azurite-blob --blobHost 0.0.0.0 --blobPort 10000 --location /data

  analytics-service:
    build:
      context: ../..
      dockerfile: Aspire/ShopDemo.Analytics.Api/Dockerfile
    container_name: shopdemo-analytics-api
    ports:
      - "8004:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - EventHubs__Enabled=${EVENT_HUBS_ENABLED:-false}
      - EventHubs__ConnectionString=${EVENT_HUBS_CONNECTION_STRING:-}
      - EventHubs__EventHubName=${EVENT_HUBS_NAME:-shopdemo-events}
      - EventHubs__ConsumerGroup=${EVENT_HUBS_CONSUMER_GROUP:-analytics-service}
      - EventHubs__CheckpointStorageConnectionString=${EVENT_HUBS_CHECKPOINT_STORAGE:-DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;}
      - EventHubs__CheckpointContainerName=${EVENT_HUBS_CHECKPOINT_CONTAINER:-analytics-checkpoints}
    depends_on:
      azurite:
        condition: service_started

volumes:
  analytics-azurite-data:
```
