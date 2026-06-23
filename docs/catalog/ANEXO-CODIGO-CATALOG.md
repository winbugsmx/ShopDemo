# Anexo — Código completo Catalog (copiar/integrar)

> Copia cada bloque en la ruta indicada. Elimina Class1.cs y placeholders.

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 1)  
**Explicación arquitectónica:** [IMPLEMENTACION-CATALOG.md](./IMPLEMENTACION-CATALOG.md)

---
## `Catalog/ShopDemo.Catalog.Api/Controllers/ProductsController.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using MediatR;
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Catalog.Application.Commands.CreateProduct;
using ShopDemo.Catalog.Application.DTOs;

namespace ShopDemo.Catalog.Api.Controllers;

[ApiController]
[Route("api/products")]
public sealed class ProductsController(IMediator mediator) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ProductDto>> Create(
        [FromBody] CreateProductCommand command,
        CancellationToken cancellationToken)
    {
        var product = await mediator.Send(command, cancellationToken);
        return CreatedAtAction(nameof(Create), new { id = product.Id }, product);
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Api/Middleware/ExceptionHandlingMiddleware.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using System.Text.Json;
using FluentValidation;
using ShopDemo.Catalog.Domain.Exceptions;

namespace ShopDemo.Catalog.Api.Middleware;

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
            ValidationException validationException => (
                StatusCodes.Status400BadRequest,
                "Validation failed",
                string.Join("; ", validationException.Errors.Select(e => e.ErrorMessage))),

            ProductDomainException domainException => (
                StatusCodes.Status400BadRequest,
                "Domain rule violation",
                domainException.Message),

            InvalidOperationException { Message: var message } when message.Contains("already exists") => (
                StatusCodes.Status409Conflict,
                "Conflict",
                message),

            KeyNotFoundException notFoundException => (
                StatusCodes.Status404NotFound,
                "Not found",
                notFoundException.Message),

            _ => (
                StatusCodes.Status500InternalServerError,
                "Internal server error",
                "An unexpected error occurred.")
        };

        if (statusCode == StatusCodes.Status500InternalServerError)
            logger.LogError(exception, "Unhandled exception");
        else
            logger.LogWarning(exception, "Handled exception: {Title}", title);

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        var problem = new
        {
            type = $"https://httpstatuses.com/{statusCode}",
            title,
            status = statusCode,
            detail,
            traceId = context.TraceIdentifier
        };

        await context.Response.WriteAsync(JsonSerializer.Serialize(problem));
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Api/Program.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using FluentValidation;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.OpenApi;
using ShopDemo.Catalog.Api.Middleware;
using ShopDemo.Catalog.Application.Commands.CreateProduct;
using ShopDemo.Catalog.Application.Common.Behaviors;
using ShopDemo.Catalog.Infraestructure;
using ShopDemo.Catalog.Infraestructure.Persistence;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ShopDemo Catalog API",
        Version = "v1",
        Description = "Microservicio de catÃ¡logo de productos"
    });
});

builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(CreateProductHandler).Assembly);
    cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
});

builder.Services.AddValidatorsFromAssemblyContaining<CreateProductValidator>();
builder.Services.AddCatalogInfrastructure(builder.Configuration);
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), ["live"]);

var app = builder.Build();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

await DatabaseInitializer.EnsureCreatedAsync(connectionString);

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<CatalogDbContext>();
    await dbContext.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "ShopDemo Catalog API v1");
        options.RoutePrefix = "swagger";
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
## `Catalog/ShopDemo.Catalog.Application/Commands/CreateProduct/CreateProductCommand.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using MediatR;
using ShopDemo.Catalog.Application.DTOs;

namespace ShopDemo.Catalog.Application.Commands.CreateProduct;

/// <summary>
/// Comando para crear un producto. Implementa IRequest de MediatR.
/// Devuelve el DTO del producto creado.
/// </summary>
public sealed record CreateProductCommand(
    string Name,
    string Description,
    decimal Price,
    string Currency,
    int Stock,
    string Category
) : IRequest<ProductDto>;
``` 

---
## `Catalog/ShopDemo.Catalog.Application/Commands/CreateProduct/CreateProductHandler.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using MediatR;
using ShopDemo.Catalog.Application.DTOs;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Catalog.Domain.Aggregates;
using ShopDemo.Catalog.Domain.Repositories;
using ShopDemo.Catalog.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Application.Commands.CreateProduct;

/// <summary>
/// Handler del comando CreateProduct.
/// Orquesta: validación → creación del Aggregate → persistencia → publicación de eventos.
/// NO contiene lógica de negocio — esa está en el Aggregate.
/// </summary>
public sealed class CreateProductHandler(
    IProductRepository productRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher
) : IRequestHandler<CreateProductCommand, ProductDto>
{
    public async Task<ProductDto> Handle(
        CreateProductCommand command, CancellationToken ct)
    {
        // 1. Construir Value Objects — el dominio valida las reglas de negocio
        var name = ProductName.Create(command.Name);
        var price = Money.Of(command.Price, command.Currency);
        var stock = StockLevel.Of(command.Stock);
        var category = Category.Of(command.Category);

        // 2. Verificar duplicados — regla de negocio
        if (await productRepository.ExistsByNameAsync(name, ct))
            throw new InvalidOperationException(
                $"A product with name '{name}' already exists.");

        // 3. Crear el Aggregate — lógica en el dominio
        var product = Product.Create(name, command.Description, price, stock, category);

        // 4. Persistir
        await productRepository.AddAsync(product, ct);
        await unitOfWork.SaveChangesAsync(ct);

        // 5. Publicar Domain Events a la infraestructura de mensajería
        await eventPublisher.PublishAsync(product.DomainEvents, ct);
        product.ClearDomainEvents();

        // 6. Retornar DTO (nunca exponer el Aggregate hacia afuera)
        return ProductDto.FromAggregate(product);
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Application/Commands/CreateProduct/CreateProductValidator.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using FluentValidation;

namespace ShopDemo.Catalog.Application.Commands.CreateProduct;

public sealed class CreateProductValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required.")
            .MinimumLength(3).WithMessage("Name must be at least 3 characters.")
            .MaximumLength(200).WithMessage("Name cannot exceed 200 characters.");

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0).WithMessage("Price cannot be negative.");

        RuleFor(x => x.Currency)
            .NotEmpty()
            .Length(3).WithMessage("Currency must be a 3-letter ISO code.");

        RuleFor(x => x.Stock)
            .GreaterThanOrEqualTo(0).WithMessage("Stock cannot be negative.");

        RuleFor(x => x.Category)
            .NotEmpty().WithMessage("Category is required.");
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Application/Common/Behaviors/ValidationBehavior.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using FluentValidation;
using MediatR;

namespace ShopDemo.Catalog.Application.Common.Behaviors;

public sealed class ValidationBehavior<TRequest, TResponse>(
    IEnumerable<IValidator<TRequest>> validators
) : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (!validators.Any())
            return await next(cancellationToken);

        var context = new ValidationContext<TRequest>(request);
        var failures = (await Task.WhenAll(
                validators.Select(v => v.ValidateAsync(context, cancellationToken))))
            .SelectMany(result => result.Errors)
            .Where(f => f is not null)
            .ToList();

        if (failures.Count > 0)
            throw new ValidationException(failures);

        return await next(cancellationToken);
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Application/DTOs/ProductDto.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Catalog.Application.DTOs;

public sealed record ProductDto(
    Guid Id,
    string Name,
    string Description,
    decimal Price,
    string Currency,
    int StockUnits,
    string Category,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastUpdatedAt
)
{
    // Mapeo desde Aggregate â€” centralizado aquÃ­, no en el Aggregate
    public static ProductDto FromAggregate(Domain.Aggregates.Product product) => new(
        product.Id,
        product.Name.Value,
        product.Description,
        product.Price.Amount,
        product.Price.Currency,
        product.Stock.Units,
        product.Category.Value,
        product.IsActive,
        product.CreatedAt,
        product.LastUpdatedAt);
}
``` 

---
## `Catalog/ShopDemo.Catalog.Application/Ports/IDomainEventPublisher.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Application.Ports;

/// <summary>
/// Puerto hacia la infraestructura de mensajerÃ­a.
/// Application define el contrato; Infrastructure (Event Hubs) lo implementa.
/// </summary>
public interface IDomainEventPublisher
{
    Task PublishAsync(IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken ct = default);
}
``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Aggregates/Product.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Catalog.Domain.Events;
using ShopDemo.Catalog.Domain.Exceptions;
using ShopDemo.Catalog.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Aggregates;

/// <summary>
/// Product Aggregate â€” nÃºcleo del Bounded Context Catalog.
/// Toda la lÃ³gica de negocio relacionada con productos vive aquÃ­.
/// </summary>
public sealed class Product : AggregateRoot<Guid>
{
    public ProductName Name { get; private set; } = null!;
    public string Description { get; private set; } = string.Empty;
    public Money Price { get; private set; } = null!;
    public StockLevel Stock { get; private set; } = null!;
    public Category Category { get; private set; } = null!;
    public bool IsActive { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset? LastUpdatedAt { get; private set; }

    // Constructor privado â€” EF Core lo necesita para rehidratar
    private Product() { }

    // â”€â”€ Factory Method â€” Ãºnica forma de crear un Product â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public static Product Create(
        ProductName name,
        string description,
        Money price,
        StockLevel stock,
        Category category)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = name,
            Description = description,
            Price = price,
            Stock = stock,
            Category = category,
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow
        };

        // Levantar Domain Event â€” otros contextos pueden reaccionar
        product.RaiseDomainEvent(new ProductCreatedDomainEvent(
            product.Id,
            product.Name.Value,
            product.Price.Amount,
            product.Price.Currency,
            product.Stock.Units,
            product.Category.Value));

        return product;
    }

    // â”€â”€ Comportamientos del Aggregate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public void UpdateDetails(ProductName? name, string? description)
    {
        GuardIsActive();

        bool changed = false;

        if (name is not null && name != Name)
        {
            Name = name;
            changed = true;
        }

        if (description is not null && description != Description)
        {
            Description = description;
            changed = true;
        }

        if (changed) MarkUpdated();
    }

    public void ChangePrice(Money newPrice)
    {
        GuardIsActive();

        if (newPrice == Price) return;

        var previousPrice = Price;
        Price = newPrice;
        MarkUpdated();

        RaiseDomainEvent(new ProductPriceChangedDomainEvent(
            Id, previousPrice.Amount, newPrice.Amount, newPrice.Currency));
    }

    public void ReplenishStock(int units)
    {
        GuardIsActive();

        if (units <= 0)
            throw new ProductDomainException("Units to replenish must be greater than zero.");

        Stock = Stock.Increase(units);
        MarkUpdated();

        RaiseDomainEvent(new StockReplenishedDomainEvent(Id, units, Stock.Units));
    }

    public void DeductStock(int units)
    {
        GuardIsActive();

        // Toda la validaciÃ³n de negocio estÃ¡ en el Value Object
        Stock = Stock.Decrease(units);
        MarkUpdated();

        if (Stock.Units == 0)
            RaiseDomainEvent(new StockDepletedDomainEvent(Id, Name.Value));
    }

    public void Deactivate()
    {
        if (!IsActive) return;
        IsActive = false;
        MarkUpdated();
        RaiseDomainEvent(new ProductDeactivatedDomainEvent(Id, Name.Value));
    }

    public bool HasSufficientStock(int quantity) => Stock.IsAvailableFor(quantity);

    // â”€â”€ Guards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    private void GuardIsActive()
    {
        if (!IsActive)
            throw new ProductDomainException($"Product '{Name}' is deactivated and cannot be modified.");
    }

    private void MarkUpdated() => LastUpdatedAt = DateTimeOffset.UtcNow;
}
``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Events/ProductCreatedDomainEvent.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Events;

public sealed record ProductCreatedDomainEvent(
    Guid ProductId,
    string Name,
    decimal Price,
    string Currency,
    int InitialStock,
    string Category
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}





``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Events/ProductDeactivatedDomainEvent.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Events;

public sealed record ProductDeactivatedDomainEvent(
    Guid ProductId,
    string ProductName
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}
``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Events/ProductPriceChangedDomainEvent.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Events;

public sealed record ProductPriceChangedDomainEvent(
    Guid ProductId,
    decimal PreviousPrice,
    decimal NewPrice,
    string Currency
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Events/StockDepletedDomainEvent.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Events;

public sealed record StockDepletedDomainEvent(
    Guid ProductId,
    string ProductName
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Events/StockReplenishedDomainEvent.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Events;

public sealed record StockReplenishedDomainEvent(
    Guid ProductId,
    int UnitsAdded,
    int TotalStock
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Exceptions/ProductDomainException.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
namespace ShopDemo.Catalog.Domain.Exceptions;

public sealed class ProductDomainException : Exception
{
    public ProductDomainException(string message) : base(message) { }
    public ProductDomainException(string message, Exception inner) : base(message, inner) { }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Domain/Repositories/IProductRepository.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Catalog.Domain.Aggregates;
using ShopDemo.Catalog.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Repositories;

/// <summary>
/// Contrato del repositorio definido en el Dominio.
/// La implementaciÃ³n concreta (EF Core) vive en Infrastructure.
/// </summary>
public interface IProductRepository : IRepository<Product, Guid>
{
    Task<IReadOnlyList<Product>> GetByCategoryAsync(
        Category category, CancellationToken ct = default);

    Task<IReadOnlyList<Product>> GetActiveProductsAsync(
        int skip, int take, CancellationToken ct = default);

    Task<int> CountActiveAsync(CancellationToken ct = default);

    Task<bool> ExistsByNameAsync(ProductName name, CancellationToken ct = default);
}``` 

---
## `Catalog/ShopDemo.Catalog.Domain/ValueObjects/Category.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class Category : ValueObject
{
    // Valores válidos del dominio — no enums para permitir extensión sin recompilación
    public static readonly Category Electronics = new("Electronics");
    public static readonly Category Clothing = new("Clothing");
    public static readonly Category Food = new("Food");
    public static readonly Category Books = new("Books");
    public static readonly Category Sports = new("Sports");

    private static readonly HashSet<string> _validCategories = new(StringComparer.OrdinalIgnoreCase)
        { "Electronics", "Clothing", "Food", "Books", "Sports" };

    public string Value { get; }

    private Category(string value) => Value = value;

    public static Category Of(string value)
    {
        if (!_validCategories.Contains(value))
            throw new ArgumentException(
                $"'{value}' is not a valid category. Valid: {string.Join(", ", _validCategories)}");
        return new Category(value);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToLowerInvariant();
    }

    public override string ToString() => Value;
}

``` 

---
## `Catalog/ShopDemo.Catalog.Domain/ValueObjects/Money.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class Money : ValueObject
{
    public decimal Amount { get; }
    public string Currency { get; }

    private Money(decimal amount, string currency)
    {
        Amount = amount;
        Currency = currency;
    }

    public static Money Of(decimal amount, string currency = "MXN")
    {
        if (amount < 0)
            throw new ArgumentException("Money amount cannot be negative.");
        if (string.IsNullOrWhiteSpace(currency) || currency.Length != 3)
            throw new ArgumentException("Currency must be a valid 3-letter ISO code.");

        return new Money(Math.Round(amount, 2), currency.ToUpperInvariant());
    }

    public Money Add(Money other)
    {
        GuardSameCurrency(other);
        return new Money(Amount + other.Amount, Currency);
    }

    public Money Subtract(Money other)
    {
        GuardSameCurrency(other);
        if (Amount < other.Amount)
            throw new InvalidOperationException("Insufficient funds.");
        return new Money(Amount - other.Amount, Currency);
    }

    public Money Multiply(int factor)
    {
        if (factor < 0)
            throw new ArgumentException("Factor cannot be negative.");
        return new Money(Amount * factor, Currency);
    }

    private void GuardSameCurrency(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException(
                $"Cannot operate between {Currency} and {other.Currency}.");
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Amount;
        yield return Currency;
    }

    public override string ToString() => $"{Amount:F2} {Currency}";
}
``` 

---
## `Catalog/ShopDemo.Catalog.Domain/ValueObjects/ProductName.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class ProductName : ValueObject
{
    public string Value { get; }

    private ProductName(string value) => Value = value;

    public static ProductName Create(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Product name cannot be empty.");
        if (value.Length < 3)
            throw new ArgumentException("Product name must be at least 3 characters.");
        if (value.Length > 200)
            throw new ArgumentException("Product name cannot exceed 200 characters.");

        return new ProductName(value.Trim());
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToLowerInvariant();
    }

    public override string ToString() => Value;

    // ConversiÃ³n implÃ­cita para comodidad
    public static implicit operator string(ProductName name) => name.Value;
}
``` 

---
## `Catalog/ShopDemo.Catalog.Domain/ValueObjects/StockLevel.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class StockLevel : ValueObject
{
    public int Units { get; }

    private StockLevel(int units) => Units = units;

    public static StockLevel Of(int units)
    {
        if (units < 0)
            throw new ArgumentException("Stock level cannot be negative.");
        return new StockLevel(units);
    }

    public static StockLevel Zero => new(0);

    public StockLevel Decrease(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity to decrease must be positive.");
        if (Units < quantity)
            throw new InvalidOperationException(
                $"Insufficient stock. Available: {Units}, requested: {quantity}.");
        return new StockLevel(Units - quantity);
    }

    public StockLevel Increase(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity to increase must be positive.");
        return new StockLevel(Units + quantity);
    }

    public bool IsAvailableFor(int quantity) => Units >= quantity;

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Units;
    }

    public override string ToString() => $"{Units} units";
}
``` 

---
## `Catalog/ShopDemo.Catalog.Infraestructure/DependencyInjection.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

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
## `Catalog/ShopDemo.Catalog.Infraestructure/Messaging/EventHubsDomainEventPublisher.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

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

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.Extensions.Logging;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure.Messaging;

/// <summary>
/// ImplementaciÃ³n de desarrollo que registra eventos en logs.
/// Sustituir por Event Hubs u otro broker en producciÃ³n.
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
## `Catalog/ShopDemo.Catalog.Infraestructure/Persistence/CatalogDbContext.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.EntityFrameworkCore;
using ShopDemo.Catalog.Domain.Aggregates;

namespace ShopDemo.Catalog.Infraestructure.Persistence;

public sealed class CatalogDbContext(DbContextOptions<CatalogDbContext> options) : DbContext(options)
{
    public DbSet<Product> Products => Set<Product>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CatalogDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Infraestructure/Persistence/Configurations/ProductConfiguration.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopDemo.Catalog.Domain.Aggregates;

namespace ShopDemo.Catalog.Infraestructure.Persistence.Configurations;

public sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("products");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Description)
            .HasMaxLength(2000)
            .IsRequired();

        builder.OwnsOne(p => p.Name, name =>
        {
            name.Property(n => n.Value)
                .HasColumnName("name")
                .HasMaxLength(200)
                .IsRequired();
        });

        builder.OwnsOne(p => p.Price, price =>
        {
            price.Property(m => m.Amount)
                .HasColumnName("price_amount")
                .HasPrecision(18, 2);

            price.Property(m => m.Currency)
                .HasColumnName("price_currency")
                .HasMaxLength(3)
                .IsRequired();
        });

        builder.OwnsOne(p => p.Stock, stock =>
        {
            stock.Property(s => s.Units)
                .HasColumnName("stock_units");
        });

        builder.OwnsOne(p => p.Category, category =>
        {
            category.Property(c => c.Value)
                .HasColumnName("category")
                .HasMaxLength(50)
                .IsRequired();
        });

        builder.Property(p => p.IsActive).IsRequired();
        builder.Property(p => p.CreatedAt).IsRequired();
        builder.Property(p => p.LastUpdatedAt);

        builder.Ignore(p => p.DomainEvents);
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Infraestructure/Persistence/DatabaseInitializer.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Npgsql;

namespace ShopDemo.Catalog.Infraestructure.Persistence;

public static class DatabaseInitializer
{
    public static async Task EnsureCreatedAsync(
        string connectionString,
        CancellationToken cancellationToken = default)
    {
        var builder = new NpgsqlConnectionStringBuilder(connectionString);
        var databaseName = builder.Database
            ?? throw new InvalidOperationException("Database name is required in the connection string.");

        builder.Database = "postgres";

        await using var connection = new NpgsqlConnection(builder.ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var checkCmd = connection.CreateCommand();
        checkCmd.CommandText = "SELECT 1 FROM pg_database WHERE datname = @name";
        checkCmd.Parameters.AddWithValue("name", databaseName);

        var exists = await checkCmd.ExecuteScalarAsync(cancellationToken) is not null;
        if (exists)
            return;

        var escapedName = databaseName.Replace("\"", "\"\"");
        var escapedUser = (builder.Username ?? "ShopDemo").Replace("\"", "\"\"");
        await using var createCmd = connection.CreateCommand();
        createCmd.CommandText = $"CREATE DATABASE \"{escapedName}\" OWNER \"{escapedUser}\"";
        await createCmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
``` 

---
## `Catalog/ShopDemo.Catalog.Infraestructure/Persistence/ProductRepository.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using Microsoft.EntityFrameworkCore;
using ShopDemo.Catalog.Domain.Aggregates;
using ShopDemo.Catalog.Domain.Repositories;
using ShopDemo.Catalog.Domain.ValueObjects;

namespace ShopDemo.Catalog.Infraestructure.Persistence;

public sealed class ProductRepository(CatalogDbContext dbContext) : IProductRepository
{
    public async Task<Product> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await dbContext.Products
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        return product ?? throw new KeyNotFoundException($"Product with id '{id}' was not found.");
    }

    public async Task<IEnumerable<Product>> GetAllAsync(CancellationToken cancellationToken = default)
        => await dbContext.Products.AsNoTracking().ToListAsync(cancellationToken);

    public async Task AddAsync(Product aggregate, CancellationToken cancellationToken = default)
        => await dbContext.Products.AddAsync(aggregate, cancellationToken);

    public Task UpdateAsync(Product aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Products.Update(aggregate);
        return Task.CompletedTask;
    }

    public Task DeleteAsync(Product aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Products.Remove(aggregate);
        return Task.CompletedTask;
    }

    public async Task<IReadOnlyList<Product>> GetByCategoryAsync(
        Category category, CancellationToken ct = default)
        => await dbContext.Products
            .AsNoTracking()
            .Where(p => p.Category.Value == category.Value)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<Product>> GetActiveProductsAsync(
        int skip, int take, CancellationToken ct = default)
        => await dbContext.Products
            .AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.Name.Value)
            .Skip(skip)
            .Take(take)
            .ToListAsync(ct);

    public Task<int> CountActiveAsync(CancellationToken ct = default)
        => dbContext.Products.CountAsync(p => p.IsActive, ct);

    public Task<bool> ExistsByNameAsync(ProductName name, CancellationToken ct = default)
        => dbContext.Products.AnyAsync(
            p => p.Name.Value.ToLower() == name.Value.ToLower(), ct);
}
``` 

---
## `Catalog/ShopDemo.Catalog.Infraestructure/Persistence/UnitOfWork.cs`

**Para qué sirve:** archivo de la etapa Catalog — ver [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md).

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure.Persistence;

public sealed class UnitOfWork(CatalogDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
``` 

---

