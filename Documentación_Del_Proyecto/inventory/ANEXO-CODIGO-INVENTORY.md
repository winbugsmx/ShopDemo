# Anexo — Código completo Inventory (copiar/integrar)

> Copia cada bloque en la ruta indicada. Elimina Class1.cs y placeholders.

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md)

---
## Source/Inventory/ShopDemo.Inventory.Api/Adapters/Http/ReservationsController.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Inventory.Application.Ports.Inbound;

namespace ShopDemo.Inventory.Api.Adapters.Http;

/// <summary>
/// Adaptador driving: endpoints de reserva/liberación invocados por Orders API.
/// </summary>
[ApiController]
[Route("api/inventory/reservations")]
public sealed class ReservationsController(
    IReserveStockUseCase reserveStock,
    IReleaseStockUseCase releaseStock) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Reserve(
        [FromBody] ReserveStockBody body, CancellationToken ct)
    {
        await reserveStock.ExecuteAsync(
            new ReserveStockRequest(
                body.OrderId,
                body.Lines.Select(l => new ReserveStockLineRequest(l.ProductId, l.Quantity)).ToList()),
            ct);

        return NoContent();
    }

    [HttpPost("release")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Release(
        [FromBody] ReleaseStockBody body, CancellationToken ct)
    {
        await releaseStock.ExecuteAsync(
            new ReleaseStockRequest(
                body.OrderId,
                body.Lines.Select(l => new ReleaseStockLineRequest(l.ProductId, l.Quantity)).ToList()),
            ct);

        return NoContent();
    }

    public sealed record ReserveStockBody(Guid OrderId, List<LineBody> Lines);
    public sealed record ReleaseStockBody(Guid OrderId, List<LineBody> Lines);
    public sealed record LineBody(Guid ProductId, int Quantity);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Api/Adapters/Http/StockController.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Inventory.Application.Ports.Inbound;

namespace ShopDemo.Inventory.Api.Adapters.Http;

/// <summary>
/// Adaptador driving (HTTP): expone operaciones de stock delegando a puertos de entrada.
/// </summary>
[ApiController]
[Route("api/inventory")]
public sealed class StockController(
    IRegisterStockUseCase registerStock,
    IGetStockByProductUseCase getStock) : ControllerBase
{
    [HttpPost("stock")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    public async Task<IActionResult> RegisterStock(
        [FromBody] RegisterStockBody body, CancellationToken ct)
    {
        var result = await registerStock.ExecuteAsync(
            new RegisterStockRequest(body.ProductId, body.ProductName, body.Units), ct);

        return CreatedAtAction(nameof(GetStock), new { productId = result.ProductId }, result);
    }

    [HttpGet("{productId:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetStock(Guid productId, CancellationToken ct)
    {
        var result = await getStock.ExecuteAsync(productId, ct);
        return result is null ? NotFound() : Ok(result);
    }

    public sealed record RegisterStockBody(Guid ProductId, string ProductName, int Units);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Api/Middleware/ExceptionHandlingMiddleware.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using System.Text.Json;
using ShopDemo.Inventory.Domain.Exceptions;

namespace ShopDemo.Inventory.Api.Middleware;

public sealed class ExceptionHandlingMiddleware(
    RequestDelegate next,
    ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, title, detail) = exception switch
        {
            InventoryDomainException domain => (
                StatusCodes.Status400BadRequest,
                "Domain rule violation",
                domain.Message),
            InvalidOperationException op => (
                StatusCodes.Status409Conflict,
                "Conflict",
                op.Message),
            KeyNotFoundException notFound => (
                StatusCodes.Status404NotFound,
                "Not found",
                notFound.Message),
            _ => (
                StatusCodes.Status500InternalServerError,
                "Internal server error",
                "An unexpected error occurred.")
        };

        if (statusCode == StatusCodes.Status500InternalServerError)
            logger.LogError(exception, "Unhandled exception");
        else
            logger.LogWarning(exception, "Handled: {Title}", title);

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new
        {
            title,
            status = statusCode,
            detail,
            traceId = context.TraceIdentifier
        }));
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Api/Program.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.OpenApi;
using ShopDemo.Inventory.Api.Middleware;
using ShopDemo.Inventory.Infrastructure;
using ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ShopDemo Inventory API",
        Version = "v1",
        Description = "Microservicio de inventario — Arquitectura Hexagonal"
    });
});

builder.Services.AddInventoryInfrastructure(builder.Configuration);
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), ["live"]);

var app = builder.Build();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

await DatabaseInitializer.EnsureCreatedAsync(connectionString);

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();
    await db.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(o =>
    {
        o.SwaggerEndpoint("/swagger/v1/swagger.json", "ShopDemo Inventory API v1");
        o.RoutePrefix = "swagger";
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.MapHealthChecks("/health");
app.MapHealthChecks("/alive", new HealthCheckOptions
{
    Predicate = r => r.Tags.Contains("live")
});
app.MapControllers();

app.Run();
```

---
## Source/Inventory/ShopDemo.Inventory.Application/DTOs/StockEntryDto.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Inventory.Application.DTOs;

public sealed record StockEntryDto(
    Guid ProductId,
    string ProductName,
    int AvailableUnits,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastUpdatedAt)
{
    public static StockEntryDto FromAggregate(Domain.Aggregates.StockEntry entry) => new(
        entry.Id,
        entry.ProductName,
        entry.AvailableUnits.Value,
        entry.CreatedAt,
        entry.LastUpdatedAt);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/Ports/Inbound/IGetStockByProductUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Application.DTOs;

namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada: consultar stock por ProductId.
/// </summary>
public interface IGetStockByProductUseCase
{
    Task<StockEntryDto?> ExecuteAsync(Guid productId, CancellationToken ct = default);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/Ports/Inbound/IRegisterStockUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Application.DTOs;

namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada (driving): registrar stock de un producto.
/// </summary>
public interface IRegisterStockUseCase
{
    Task<StockEntryDto> ExecuteAsync(RegisterStockRequest request, CancellationToken ct = default);
}

public sealed record RegisterStockRequest(Guid ProductId, string ProductName, int Units);
```

---
## Source/Inventory/ShopDemo.Inventory.Application/Ports/Inbound/IReleaseStockUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada: liberar stock al cancelar un pedido confirmado.
/// </summary>
public interface IReleaseStockUseCase
{
    Task ExecuteAsync(ReleaseStockRequest request, CancellationToken ct = default);
}

public sealed record ReleaseStockRequest(
    Guid OrderId,
    IReadOnlyList<ReleaseStockLineRequest> Lines);

public sealed record ReleaseStockLineRequest(Guid ProductId, int Quantity);
```

---
## Source/Inventory/ShopDemo.Inventory.Application/Ports/Inbound/IReserveStockUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada: reservar stock al confirmar un pedido (invocado por Orders).
/// </summary>
public interface IReserveStockUseCase
{
    Task ExecuteAsync(ReserveStockRequest request, CancellationToken ct = default);
}

public sealed record ReserveStockRequest(
    Guid OrderId,
    IReadOnlyList<ReserveStockLineRequest> Lines);

public sealed record ReserveStockLineRequest(Guid ProductId, int Quantity);
```

---
## Source/Inventory/ShopDemo.Inventory.Application/Ports/Outbound/IIntegrationEventPublisher.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.Ports.Outbound;

/// <summary>
/// Puerto de salida: publicar eventos de integración hacia el bus de mensajería.
/// </summary>
public interface IIntegrationEventPublisher
{
    Task PublishAsync(IReadOnlyCollection<IDomainEvent> events, CancellationToken ct = default);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/Ports/Outbound/IStockEntryRepository.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Application.Ports.Outbound;

/// <summary>
/// Puerto de salida (driven): persistencia del agregado StockEntry.
/// </summary>
public interface IStockEntryRepository
{
    Task<StockEntry?> GetByProductIdAsync(Guid productId, CancellationToken ct = default);
    Task<bool> ExistsAsync(Guid productId, CancellationToken ct = default);
    Task AddAsync(StockEntry entry, CancellationToken ct = default);
    Task UpdateAsync(StockEntry entry, CancellationToken ct = default);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/UseCases/GetStockByProductUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Application.DTOs;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: consulta el stock disponible de un producto.
/// </summary>
public sealed class GetStockByProductUseCase(IStockEntryRepository repository)
    : IGetStockByProductUseCase
{
    public async Task<StockEntryDto?> ExecuteAsync(Guid productId, CancellationToken ct = default)
    {
        var entry = await repository.GetByProductIdAsync(productId, ct);
        return entry is null ? null : StockEntryDto.FromAggregate(entry);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/UseCases/RegisterStockUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Application.DTOs;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Aggregates;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Inventory.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: registra stock inicial o reabastece un producto existente.
/// Implementa el puerto de entrada IRegisterStockUseCase.
/// </summary>
public sealed class RegisterStockUseCase(
    IStockEntryRepository repository,
    IUnitOfWork unitOfWork,
    IIntegrationEventPublisher eventPublisher
) : IRegisterStockUseCase
{
    public async Task<StockEntryDto> ExecuteAsync(RegisterStockRequest request, CancellationToken ct = default)
    {
        var product = ProductReference.Create(request.ProductId, request.ProductName);
        var units = StockQuantity.Of(request.Units);

        var existing = await repository.GetByProductIdAsync(request.ProductId, ct);

        if (existing is null)
        {
            var entry = StockEntry.Register(product, units);
            await repository.AddAsync(entry, ct);
            await unitOfWork.SaveChangesAsync(ct);
            await eventPublisher.PublishAsync(entry.DomainEvents, ct);
            entry.ClearDomainEvents();
            return StockEntryDto.FromAggregate(entry);
        }

        existing.Replenish(request.Units);
        await repository.UpdateAsync(existing, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return StockEntryDto.FromAggregate(existing);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/UseCases/ReleaseStockUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: libera stock previamente reservado al cancelar un pedido.
/// </summary>
public sealed class ReleaseStockUseCase(
    IStockEntryRepository repository,
    IUnitOfWork unitOfWork,
    IIntegrationEventPublisher eventPublisher
) : IReleaseStockUseCase
{
    public async Task ExecuteAsync(ReleaseStockRequest request, CancellationToken ct = default)
    {
        foreach (var line in request.Lines)
        {
            var entry = await repository.GetByProductIdAsync(line.ProductId, ct)
                ?? throw new InventoryDomainException(
                    $"No stock entry found for product '{line.ProductId}'.");

            entry.Release(line.Quantity, request.OrderId);
            await repository.UpdateAsync(entry, ct);
            await eventPublisher.PublishAsync(entry.DomainEvents, ct);
            entry.ClearDomainEvents();
        }

        await unitOfWork.SaveChangesAsync(ct);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Application/UseCases/ReserveStockUseCase.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: reserva stock para las líneas de un pedido confirmado.
/// Invocado por Orders API vía HTTP.
/// </summary>
public sealed class ReserveStockUseCase(
    IStockEntryRepository repository,
    IUnitOfWork unitOfWork,
    IIntegrationEventPublisher eventPublisher
) : IReserveStockUseCase
{
    public async Task ExecuteAsync(ReserveStockRequest request, CancellationToken ct = default)
    {
        foreach (var line in request.Lines)
        {
            var entry = await repository.GetByProductIdAsync(line.ProductId, ct)
                ?? throw new InventoryDomainException(
                    $"No stock entry found for product '{line.ProductId}'.");

            entry.Reserve(line.Quantity, request.OrderId);
            await repository.UpdateAsync(entry, ct);
            await eventPublisher.PublishAsync(entry.DomainEvents, ct);
            entry.ClearDomainEvents();
        }

        await unitOfWork.SaveChangesAsync(ct);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Domain/Aggregates/StockEntry.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Inventory.Domain.Events;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Inventory.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.Aggregates;

/// <summary>
/// Agregado raíz de inventario. El Id coincide con ProductId de Catalog.
/// </summary>
public sealed class StockEntry : AggregateRoot<Guid>
{
    public string ProductName { get; private set; } = string.Empty;
    public StockQuantity AvailableUnits { get; private set; } = StockQuantity.Zero;
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset? LastUpdatedAt { get; private set; }

    private StockEntry() { }

    public static StockEntry Register(ProductReference product, StockQuantity initialUnits)
    {
        var entry = new StockEntry
        {
            Id = product.ProductId,
            ProductName = product.ProductName,
            AvailableUnits = initialUnits,
            CreatedAt = DateTimeOffset.UtcNow
        };

        entry.RaiseDomainEvent(new StockEntryRegisteredDomainEvent(
            entry.Id, entry.ProductName, entry.AvailableUnits.Value));

        return entry;
    }

    public void Replenish(int units)
    {
        if (units <= 0)
            throw new InventoryDomainException("Replenish units must be greater than zero.");

        AvailableUnits = AvailableUnits.Increase(units);
        MarkUpdated();
    }

    public void Reserve(int units, Guid orderId)
    {
        if (units <= 0)
            throw new InventoryDomainException("Reserve units must be greater than zero.");

        var previous = AvailableUnits.Value;
        AvailableUnits = AvailableUnits.Decrease(units);
        MarkUpdated();

        RaiseDomainEvent(new StockReservedDomainEvent(Id, orderId, units, AvailableUnits.Value));

        if (AvailableUnits.Value == 0)
            RaiseDomainEvent(new StockDepletedDomainEvent(Id, ProductName));
    }

    public void Release(int units, Guid orderId)
    {
        if (units <= 0)
            throw new InventoryDomainException("Release units must be greater than zero.");

        AvailableUnits = AvailableUnits.Increase(units);
        MarkUpdated();

        RaiseDomainEvent(new StockReleasedDomainEvent(Id, orderId, units, AvailableUnits.Value));
    }

    private void MarkUpdated() => LastUpdatedAt = DateTimeOffset.UtcNow;
}
```

---
## Source/Inventory/ShopDemo.Inventory.Domain/Events/InventoryDomainEvents.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.Events;

public sealed record StockEntryRegisteredDomainEvent(
    Guid ProductId,
    string ProductName,
    int InitialUnits
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}

public sealed record StockReservedDomainEvent(
    Guid ProductId,
    Guid OrderId,
    int UnitsReserved,
    int RemainingUnits
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}

public sealed record StockReleasedDomainEvent(
    Guid ProductId,
    Guid OrderId,
    int UnitsReleased,
    int AvailableUnits
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}

public sealed record StockDepletedDomainEvent(
    Guid ProductId,
    string ProductName
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}
```

---
## Source/Inventory/ShopDemo.Inventory.Domain/Exceptions/InventoryDomainException.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Inventory.Domain.Exceptions;

public sealed class InventoryDomainException : Exception
{
    public InventoryDomainException(string message) : base(message) { }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Domain/ValueObjects/ProductReference.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.ValueObjects;

public sealed class ProductReference : ValueObject
{
    public Guid ProductId { get; }
    public string ProductName { get; }

    private ProductReference(Guid productId, string productName)
    {
        ProductId = productId;
        ProductName = productName;
    }

    public static ProductReference Create(Guid productId, string productName)
    {
        if (productId == Guid.Empty)
            throw new ArgumentException("ProductId cannot be empty.");
        if (string.IsNullOrWhiteSpace(productName))
            throw new ArgumentException("ProductName is required.");

        return new ProductReference(productId, productName.Trim());
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return ProductId;
        yield return ProductName.ToLowerInvariant();
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Domain/ValueObjects/StockQuantity.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.ValueObjects;

public sealed class StockQuantity : ValueObject
{
    public int Value { get; }

    private StockQuantity(int value) => Value = value;

    public static StockQuantity Of(int value)
    {
        if (value < 0)
            throw new ArgumentException("Stock quantity cannot be negative.");
        return new StockQuantity(value);
    }

    public static StockQuantity Zero => new(0);

    public StockQuantity Decrease(int units)
    {
        if (units <= 0)
            throw new ArgumentException("Units to decrease must be positive.");
        if (Value < units)
            throw new InvalidOperationException(
                $"Insufficient stock. Available: {Value}, requested: {units}.");
        return new StockQuantity(Value - units);
    }

    public StockQuantity Increase(int units)
    {
        if (units <= 0)
            throw new ArgumentException("Units to increase must be positive.");
        return new StockQuantity(Value + units);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/CatalogEventsProcessor.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

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
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/EventHubsIntegrationEventPublisher.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

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
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Messaging/LoggingIntegrationEventPublisher.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

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
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Persistence/Configurations/StockEntryConfiguration.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence.Configurations;

public sealed class StockEntryConfiguration : IEntityTypeConfiguration<StockEntry>
{
    public void Configure(EntityTypeBuilder<StockEntry> builder)
    {
        builder.ToTable("stock_entries");
        builder.HasKey(s => s.Id);

        builder.Property(s => s.ProductName)
            .HasColumnName("product_name")
            .HasMaxLength(200)
            .IsRequired();

        builder.OwnsOne(s => s.AvailableUnits, q =>
        {
            q.Property(x => x.Value).HasColumnName("available_units").IsRequired();
        });

        builder.Property(s => s.CreatedAt).HasColumnName("created_at").IsRequired();
        builder.Property(s => s.LastUpdatedAt).HasColumnName("last_updated_at");

        builder.Ignore(s => s.DomainEvents);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Persistence/DatabaseInitializer.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Npgsql;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

public static class DatabaseInitializer
{
    public static async Task EnsureCreatedAsync(
        string connectionString, CancellationToken cancellationToken = default)
    {
        var builder = new NpgsqlConnectionStringBuilder(connectionString);
        var databaseName = builder.Database
            ?? throw new InvalidOperationException("Database name is required.");

        builder.Database = "postgres";

        await using var connection = new NpgsqlConnection(builder.ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var checkCmd = connection.CreateCommand();
        checkCmd.CommandText = "SELECT 1 FROM pg_database WHERE datname = @name";
        checkCmd.Parameters.AddWithValue("name", databaseName);

        var exists = await checkCmd.ExecuteScalarAsync(cancellationToken) is not null;
        if (exists) return;

        var escapedName = databaseName.Replace("\"", "\"\"");
        var escapedUser = (builder.Username ?? "ShopDemo").Replace("\"", "\"\"");
        await using var createCmd = connection.CreateCommand();
        createCmd.CommandText = $"CREATE DATABASE \"{escapedName}\" OWNER \"{escapedUser}\"";
        await createCmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Persistence/InventoryDbContext.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.EntityFrameworkCore;
using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

public sealed class InventoryDbContext(DbContextOptions<InventoryDbContext> options) : DbContext(options)
{
    public DbSet<StockEntry> StockEntries => Set<StockEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(InventoryDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Persistence/StockEntryRepository.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.EntityFrameworkCore;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

/// <summary>
/// Adaptador driven: implementa IStockEntryRepository con EF Core.
/// </summary>
public sealed class StockEntryRepository(InventoryDbContext dbContext) : IStockEntryRepository
{
    public Task<StockEntry?> GetByProductIdAsync(Guid productId, CancellationToken ct = default)
        => dbContext.StockEntries.FirstOrDefaultAsync(s => s.Id == productId, ct);

    public Task<bool> ExistsAsync(Guid productId, CancellationToken ct = default)
        => dbContext.StockEntries.AnyAsync(s => s.Id == productId, ct);

    public async Task AddAsync(StockEntry entry, CancellationToken ct = default)
        => await dbContext.StockEntries.AddAsync(entry, ct);

    public Task UpdateAsync(StockEntry entry, CancellationToken ct = default)
    {
        dbContext.StockEntries.Update(entry);
        return Task.CompletedTask;
    }
}
```

---
## Source/Inventory/ShopDemo.Inventory.Infrastructure/Adapters/Persistence/UnitOfWork.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

public sealed class UnitOfWork(InventoryDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
```

---
## Source/Inventory/ShopDemo.Inventory.Infrastructure/DependencyInjection.cs

**Para qué sirve:** archivo de la etapa Inventory — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

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
