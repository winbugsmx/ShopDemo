# Documento de Implementación — Microservicio Orders (ShopDemo)

| Campo | Detalle |
|:------|:--------|
| **Empresa** | Lite Thinking |
| **Curso** | Microservicios con .NET en Kubernetes y Entornos Multicloud |
| **Instructor** | Lcc. Gilberto Valentino Juárez Sánchez |
| **Contacto** | WhatsApp: +52 5614206660 |
| | E-mail: gilberto.juarez@gmail.com |
| | E-mail: lcc.gilberto.juarez@gmail.com |

**Tipo:** Guía de implementación con código funcional de referencia  
**Versión:** 1.0  
**Prerequisito:** Catalog implementado + `ShopDemo.Shared` disponible

> Este documento contiene el código completo de referencia. Los alumnos deben implementarlo siguiendo `REQUERIMIENTOS-ORDERS.md` y usar este documento para validar su solución.

---

## Índice

1. [Configuración inicial de proyectos](#1-configuración-inicial-de-proyectos)
2. [Capa Domain](#2-capa-domain)
3. [Capa Application](#3-capa-application)
4. [Capa Infrastructure](#4-capa-infrastructure)
5. [Capa API](#5-capa-api)
6. [Docker](#6-docker)
7. [Migraciones y ejecución](#7-migraciones-y-ejecución)
8. [Pruebas manuales](#8-pruebas-manuales)

---

## 1. Configuración inicial de proyectos

### 1.1 Referencias entre proyectos

```bash
cd I:\Curso\ShopDemo

# Domain
dotnet add ShopDemo.Orders.Domain/ShopDemo.Orders.Domain.csproj reference ShopDemo.Shared/ShopDemo.Shared.csproj

# Application
dotnet add ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj reference ShopDemo.Orders.Domain/ShopDemo.Orders.Domain.csproj
dotnet add ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj package MediatR
dotnet add ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj package FluentValidation
dotnet add ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj package FluentValidation.DependencyInjectionExtensions

# Infrastructure
dotnet add ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj reference ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj
dotnet add ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj reference ShopDemo.Orders.Domain/ShopDemo.Orders.Domain.csproj
dotnet add ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj reference ShopDemo.Shared/ShopDemo.Shared.csproj
dotnet add ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj package Microsoft.EntityFrameworkCore
dotnet add ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj package Npgsql.EntityFrameworkCore.PostgreSQL

# Api
dotnet add ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj reference ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj
dotnet add ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj reference ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj
dotnet add ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj package Swashbuckle.AspNetCore
dotnet add ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj package Microsoft.EntityFrameworkCore.Design
```

### 1.2 Eliminar placeholders

Eliminar los archivos `Class1.cs` de cada proyecto Orders.*

---

## 2. Capa Domain

### 2.1 Value Objects

#### `ShopDemo.Orders.Domain/ValueObjects/CustomerId.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class CustomerId : ValueObject
{
    public Guid Value { get; }

    private CustomerId(Guid value) => Value = value;

    public static CustomerId Of(Guid value)
    {
        if (value == Guid.Empty)
            throw new ArgumentException("CustomerId cannot be empty.");
        return new CustomerId(value);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }

    public override string ToString() => Value.ToString();
}
```

#### `ShopDemo.Orders.Domain/ValueObjects/Money.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

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

    public static Money Zero(string currency = "MXN") => Of(0, currency);

    public Money Add(Money other)
    {
        GuardSameCurrency(other);
        return new Money(Amount + other.Amount, Currency);
    }

    public Money Multiply(int factor)
    {
        if (factor <= 0)
            throw new ArgumentException("Factor must be greater than zero.");
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

#### `ShopDemo.Orders.Domain/ValueObjects/Quantity.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class Quantity : ValueObject
{
    public int Value { get; }

    private Quantity(int value) => Value = value;

    public static Quantity Of(int value)
    {
        if (value <= 0)
            throw new ArgumentException("Quantity must be greater than zero.");
        return new Quantity(value);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }

    public override string ToString() => Value.ToString();
}
```

#### `ShopDemo.Orders.Domain/ValueObjects/OrderStatus.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class OrderStatus : ValueObject
{
    public static readonly OrderStatus Pending   = new("Pending");
    public static readonly OrderStatus Confirmed = new("Confirmed");
    public static readonly OrderStatus Shipped   = new("Shipped");
    public static readonly OrderStatus Delivered  = new("Delivered");
    public static readonly OrderStatus Cancelled  = new("Cancelled");

    private static readonly HashSet<string> ValidStatuses = new(StringComparer.OrdinalIgnoreCase)
        { "Pending", "Confirmed", "Shipped", "Delivered", "Cancelled" };

    public string Value { get; }

    private OrderStatus(string value) => Value = value;

    public static OrderStatus Of(string value)
    {
        if (!ValidStatuses.Contains(value))
            throw new ArgumentException(
                $"'{value}' is not a valid order status. Valid: {string.Join(", ", ValidStatuses)}");
        return new OrderStatus(value);
    }

    public bool IsPending   => Value == Pending.Value;
    public bool IsConfirmed => Value == Confirmed.Value;
    public bool IsShipped   => Value == Shipped.Value;
    public bool IsDelivered => Value == Delivered.Value;
    public bool IsCancelled => Value == Cancelled.Value;

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToLowerInvariant();
    }

    public override string ToString() => Value;
}
```

#### `ShopDemo.Orders.Domain/ValueObjects/ShippingAddress.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class ShippingAddress : ValueObject
{
    public string Street { get; }
    public string City { get; }
    public string PostalCode { get; }
    public string Country { get; }

    private ShippingAddress(string street, string city, string postalCode, string country)
    {
        Street = street;
        City = city;
        PostalCode = postalCode;
        Country = country;
    }

    public static ShippingAddress Create(
        string street, string city, string postalCode, string country)
    {
        if (string.IsNullOrWhiteSpace(street))
            throw new ArgumentException("Street is required.");
        if (string.IsNullOrWhiteSpace(city))
            throw new ArgumentException("City is required.");
        if (string.IsNullOrWhiteSpace(postalCode))
            throw new ArgumentException("Postal code is required.");
        if (string.IsNullOrWhiteSpace(country))
            throw new ArgumentException("Country is required.");

        return new ShippingAddress(
            street.Trim(), city.Trim(), postalCode.Trim(), country.Trim().ToUpperInvariant());
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Street.ToLowerInvariant();
        yield return City.ToLowerInvariant();
        yield return PostalCode.ToLowerInvariant();
        yield return Country.ToLowerInvariant();
    }
}
```

### 2.2 Entidad hija

#### `ShopDemo.Orders.Domain/Entities/OrderLine.cs`

```csharp
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Entities;

public sealed class OrderLine : Entity<Guid>
{
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; } = string.Empty;
    public Money UnitPrice { get; private set; } = null!;
    public Quantity Quantity { get; private set; } = null!;
    public Money LineTotal { get; private set; } = null!;

    private OrderLine() { }

    internal static OrderLine Create(
        Guid productId,
        string productName,
        Money unitPrice,
        Quantity quantity)
    {
        if (productId == Guid.Empty)
            throw new ArgumentException("ProductId cannot be empty.");
        if (string.IsNullOrWhiteSpace(productName))
            throw new ArgumentException("ProductName is required.");

        return new OrderLine
        {
            Id = Guid.NewGuid(),
            ProductId = productId,
            ProductName = productName.Trim(),
            UnitPrice = unitPrice,
            Quantity = quantity,
            LineTotal = unitPrice.Multiply(quantity.Value)
        };
    }
}
```

### 2.3 Agregado raíz

#### `ShopDemo.Orders.Domain/Aggregates/Order.cs`

```csharp
using ShopDemo.Orders.Domain.Entities;
using ShopDemo.Orders.Domain.Events;
using ShopDemo.Orders.Domain.Exceptions;
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Aggregates;

public sealed class Order : AggregateRoot<Guid>
{
    private readonly List<OrderLine> _lines = [];

    public CustomerId CustomerId { get; private set; } = null!;
    public ShippingAddress ShippingAddress { get; private set; } = null!;
    public OrderStatus Status { get; private set; } = null!;
    public Money TotalAmount { get; private set; } = null!;
    public IReadOnlyCollection<OrderLine> Lines => _lines.AsReadOnly();
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset? LastUpdatedAt { get; private set; }

    private Order() { }

    public static Order Place(
        CustomerId customerId,
        ShippingAddress shippingAddress,
        IEnumerable<(Guid ProductId, string ProductName, Money UnitPrice, Quantity Quantity)> lines)
    {
        var lineList = lines.ToList();

        if (lineList.Count == 0)
            throw new OrderDomainException("An order must have at least one line.");

        var currency = lineList[0].UnitPrice.Currency;
        if (lineList.Any(l => l.UnitPrice.Currency != currency))
            throw new OrderDomainException("All order lines must use the same currency.");

        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            ShippingAddress = shippingAddress,
            Status = OrderStatus.Pending,
            TotalAmount = Money.Zero(currency),
            CreatedAt = DateTimeOffset.UtcNow
        };

        foreach (var line in lineList)
        {
            var orderLine = OrderLine.Create(
                line.ProductId, line.ProductName, line.UnitPrice, line.Quantity);
            order._lines.Add(orderLine);
            order.TotalAmount = order.TotalAmount.Add(orderLine.LineTotal);
        }

        order.RaiseDomainEvent(new OrderPlacedDomainEvent(
            order.Id,
            order.CustomerId.Value,
            order.TotalAmount.Amount,
            order.TotalAmount.Currency,
            order.Lines.Count));

        return order;
    }

    public void Confirm()
    {
        GuardNotCancelled();

        if (!Status.IsPending)
            throw new OrderDomainException(
                $"Order can only be confirmed from Pending status. Current: {Status}.");

        Status = OrderStatus.Confirmed;
        MarkUpdated();

        RaiseDomainEvent(new OrderConfirmedDomainEvent(Id, CustomerId.Value, TotalAmount.Amount, TotalAmount.Currency));
    }

    public void Cancel(string reason)
    {
        GuardNotCancelled();

        if (Status.IsDelivered)
            throw new OrderDomainException("A delivered order cannot be cancelled.");
        if (Status.IsShipped)
            throw new OrderDomainException("A shipped order cannot be cancelled.");
        if (string.IsNullOrWhiteSpace(reason))
            throw new OrderDomainException("Cancellation reason is required.");

        Status = OrderStatus.Cancelled;
        MarkUpdated();

        RaiseDomainEvent(new OrderCancelledDomainEvent(Id, CustomerId.Value, reason.Trim()));
    }

    public void MarkAsShipped()
    {
        GuardNotCancelled();

        if (!Status.IsConfirmed)
            throw new OrderDomainException(
                $"Order can only be shipped from Confirmed status. Current: {Status}.");

        Status = OrderStatus.Shipped;
        MarkUpdated();

        RaiseDomainEvent(new OrderShippedDomainEvent(Id, CustomerId.Value));
    }

    private void GuardNotCancelled()
    {
        if (Status.IsCancelled)
            throw new OrderDomainException("A cancelled order cannot be modified.");
    }

    private void MarkUpdated() => LastUpdatedAt = DateTimeOffset.UtcNow;
}
```

### 2.4 Domain Events

#### `ShopDemo.Orders.Domain/Events/OrderPlacedDomainEvent.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Events;

public sealed record OrderPlacedDomainEvent(
    Guid OrderId,
    Guid CustomerId,
    decimal TotalAmount,
    string Currency,
    int LineCount
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}
```

#### `ShopDemo.Orders.Domain/Events/OrderConfirmedDomainEvent.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Events;

public sealed record OrderConfirmedDomainEvent(
    Guid OrderId,
    Guid CustomerId,
    decimal TotalAmount,
    string Currency
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}
```

#### `ShopDemo.Orders.Domain/Events/OrderCancelledDomainEvent.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Events;

public sealed record OrderCancelledDomainEvent(
    Guid OrderId,
    Guid CustomerId,
    string Reason
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}
```

#### `ShopDemo.Orders.Domain/Events/OrderShippedDomainEvent.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Events;

public sealed record OrderShippedDomainEvent(
    Guid OrderId,
    Guid CustomerId
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}
```

### 2.5 Repositorio y excepciones

#### `ShopDemo.Orders.Domain/Repositories/IOrderRepository.cs`

```csharp
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Repositories;

public interface IOrderRepository : IRepository<Order, Guid>
{
    Task<IReadOnlyList<Order>> GetByCustomerAsync(
        CustomerId customerId, CancellationToken ct = default);

    Task<IReadOnlyList<Order>> GetByStatusAsync(
        OrderStatus status, int skip, int take, CancellationToken ct = default);
}
```

#### `ShopDemo.Orders.Domain/Exceptions/OrderDomainException.cs`

```csharp
namespace ShopDemo.Orders.Domain.Exceptions;

public sealed class OrderDomainException : Exception
{
    public OrderDomainException(string message) : base(message) { }
    public OrderDomainException(string message, Exception inner) : base(message, inner) { }
}
```

---

## 3. Capa Application

### 3.1 DTOs

#### `ShopDemo.Orders.Application/DTOs/OrderLineDto.cs`

```csharp
namespace ShopDemo.Orders.Application.DTOs;

public sealed record OrderLineDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    decimal UnitPrice,
    string Currency,
    int Quantity,
    decimal LineTotal
);
```

#### `ShopDemo.Orders.Application/DTOs/OrderDto.cs`

```csharp
using ShopDemo.Orders.Domain.Aggregates;

namespace ShopDemo.Orders.Application.DTOs;

public sealed record OrderDto(
    Guid Id,
    Guid CustomerId,
    string Status,
    decimal TotalAmount,
    string Currency,
    ShippingAddressDto ShippingAddress,
    IReadOnlyList<OrderLineDto> Lines,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastUpdatedAt
)
{
    public static OrderDto FromAggregate(Order order) => new(
        order.Id,
        order.CustomerId.Value,
        order.Status.Value,
        order.TotalAmount.Amount,
        order.TotalAmount.Currency,
        new ShippingAddressDto(
            order.ShippingAddress.Street,
            order.ShippingAddress.City,
            order.ShippingAddress.PostalCode,
            order.ShippingAddress.Country),
        order.Lines.Select(l => new OrderLineDto(
            l.Id,
            l.ProductId,
            l.ProductName,
            l.UnitPrice.Amount,
            l.UnitPrice.Currency,
            l.Quantity.Value,
            l.LineTotal.Amount)).ToList(),
        order.CreatedAt,
        order.LastUpdatedAt);
}

public sealed record ShippingAddressDto(
    string Street,
    string City,
    string PostalCode,
    string Country
);
```

### 3.2 Ports

#### `ShopDemo.Orders.Application/Ports/IDomainEventPublisher.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Ports;

public interface IDomainEventPublisher
{
    Task PublishAsync(IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken ct = default);
}
```

### 3.3 Behavior

#### `ShopDemo.Orders.Application/Common/Behaviors/ValidationBehavior.cs`

```csharp
using FluentValidation;
using MediatR;

namespace ShopDemo.Orders.Application.Common.Behaviors;

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
            .SelectMany(r => r.Errors)
            .Where(f => f is not null)
            .ToList();

        if (failures.Count > 0)
            throw new ValidationException(failures);

        return await next(cancellationToken);
    }
}
```

### 3.4 Comando PlaceOrder

#### `ShopDemo.Orders.Application/Commands/PlaceOrder/PlaceOrderCommand.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Commands.PlaceOrder;

public sealed record PlaceOrderCommand(
    Guid CustomerId,
    ShippingAddressDto ShippingAddress,
    IReadOnlyList<PlaceOrderLineDto> Lines
) : IRequest<OrderDto>;

public sealed record PlaceOrderLineDto(
    Guid ProductId,
    string ProductName,
    decimal UnitPrice,
    string Currency,
    int Quantity
);
```

#### `ShopDemo.Orders.Application/Commands/PlaceOrder/PlaceOrderValidator.cs`

```csharp
using FluentValidation;

namespace ShopDemo.Orders.Application.Commands.PlaceOrder;

public sealed class PlaceOrderValidator : AbstractValidator<PlaceOrderCommand>
{
    public PlaceOrderValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty().WithMessage("CustomerId is required.");

        RuleFor(x => x.ShippingAddress.Street).NotEmpty();
        RuleFor(x => x.ShippingAddress.City).NotEmpty();
        RuleFor(x => x.ShippingAddress.PostalCode).NotEmpty();
        RuleFor(x => x.ShippingAddress.Country).NotEmpty();

        RuleFor(x => x.Lines)
            .NotEmpty().WithMessage("Order must have at least one line.");

        RuleForEach(x => x.Lines).ChildRules(line =>
        {
            line.RuleFor(l => l.ProductId).NotEmpty();
            line.RuleFor(l => l.ProductName).NotEmpty().MinimumLength(3);
            line.RuleFor(l => l.UnitPrice).GreaterThanOrEqualTo(0);
            line.RuleFor(l => l.Currency).NotEmpty().Length(3);
            line.RuleFor(l => l.Quantity).GreaterThan(0);
        });
    }
}
```

#### `ShopDemo.Orders.Application/Commands/PlaceOrder/PlaceOrderHandler.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Commands.PlaceOrder;

public sealed class PlaceOrderHandler(
    IOrderRepository orderRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher
) : IRequestHandler<PlaceOrderCommand, OrderDto>
{
    public async Task<OrderDto> Handle(PlaceOrderCommand command, CancellationToken ct)
    {
        var customerId = CustomerId.Of(command.CustomerId);
        var address = ShippingAddress.Create(
            command.ShippingAddress.Street,
            command.ShippingAddress.City,
            command.ShippingAddress.PostalCode,
            command.ShippingAddress.Country);

        var lines = command.Lines.Select(l => (
            l.ProductId,
            l.ProductName,
            Money.Of(l.UnitPrice, l.Currency),
            Quantity.Of(l.Quantity)));

        var order = Order.Place(customerId, address, lines);

        await orderRepository.AddAsync(order, ct);
        await unitOfWork.SaveChangesAsync(ct);

        await eventPublisher.PublishAsync(order.DomainEvents, ct);
        order.ClearDomainEvents();

        return OrderDto.FromAggregate(order);
    }
}
```

### 3.5 Comando ConfirmOrder

#### `ShopDemo.Orders.Application/Commands/ConfirmOrder/ConfirmOrderCommand.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Commands.ConfirmOrder;

public sealed record ConfirmOrderCommand(Guid OrderId) : IRequest<OrderDto>;
```

#### `ShopDemo.Orders.Application/Commands/ConfirmOrder/ConfirmOrderHandler.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Commands.ConfirmOrder;

public sealed class ConfirmOrderHandler(
    IOrderRepository orderRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher
) : IRequestHandler<ConfirmOrderCommand, OrderDto>
{
    public async Task<OrderDto> Handle(ConfirmOrderCommand command, CancellationToken ct)
    {
        var order = await orderRepository.GetByIdAsync(command.OrderId, ct);

        order.Confirm();

        await orderRepository.UpdateAsync(order, ct);
        await unitOfWork.SaveChangesAsync(ct);

        await eventPublisher.PublishAsync(order.DomainEvents, ct);
        order.ClearDomainEvents();

        return OrderDto.FromAggregate(order);
    }
}
```

### 3.6 Comando CancelOrder

#### `ShopDemo.Orders.Application/Commands/CancelOrder/CancelOrderCommand.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Commands.CancelOrder;

public sealed record CancelOrderCommand(Guid OrderId, string Reason) : IRequest<OrderDto>;
```

#### `ShopDemo.Orders.Application/Commands/CancelOrder/CancelOrderValidator.cs`

```csharp
using FluentValidation;

namespace ShopDemo.Orders.Application.Commands.CancelOrder;

public sealed class CancelOrderValidator : AbstractValidator<CancelOrderCommand>
{
    public CancelOrderValidator()
    {
        RuleFor(x => x.OrderId).NotEmpty();
        RuleFor(x => x.Reason).NotEmpty().MaximumLength(500);
    }
}
```

#### `ShopDemo.Orders.Application/Commands/CancelOrder/CancelOrderHandler.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Commands.CancelOrder;

public sealed class CancelOrderHandler(
    IOrderRepository orderRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher
) : IRequestHandler<CancelOrderCommand, OrderDto>
{
    public async Task<OrderDto> Handle(CancelOrderCommand command, CancellationToken ct)
    {
        var order = await orderRepository.GetByIdAsync(command.OrderId, ct);

        order.Cancel(command.Reason);

        await orderRepository.UpdateAsync(order, ct);
        await unitOfWork.SaveChangesAsync(ct);

        await eventPublisher.PublishAsync(order.DomainEvents, ct);
        order.ClearDomainEvents();

        return OrderDto.FromAggregate(order);
    }
}
```

### 3.7 Queries

#### `ShopDemo.Orders.Application/Queries/GetOrderById/GetOrderByIdQuery.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Queries.GetOrderById;

public sealed record GetOrderByIdQuery(Guid OrderId) : IRequest<OrderDto?>;
```

#### `ShopDemo.Orders.Application/Queries/GetOrderById/GetOrderByIdHandler.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Domain.Repositories;

namespace ShopDemo.Orders.Application.Queries.GetOrderById;

public sealed class GetOrderByIdHandler(IOrderRepository orderRepository)
    : IRequestHandler<GetOrderByIdQuery, OrderDto?>
{
    public async Task<OrderDto?> Handle(GetOrderByIdQuery query, CancellationToken ct)
    {
        try
        {
            var order = await orderRepository.GetByIdAsync(query.OrderId, ct);
            return OrderDto.FromAggregate(order);
        }
        catch (KeyNotFoundException)
        {
            return null;
        }
    }
}
```

#### `ShopDemo.Orders.Application/Queries/GetOrdersByCustomer/GetOrdersByCustomerQuery.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Queries.GetOrdersByCustomer;

public sealed record GetOrdersByCustomerQuery(Guid CustomerId) : IRequest<IReadOnlyList<OrderDto>>;
```

#### `ShopDemo.Orders.Application/Queries/GetOrdersByCustomer/GetOrdersByCustomerHandler.cs`

```csharp
using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Domain.ValueObjects;

namespace ShopDemo.Orders.Application.Queries.GetOrdersByCustomer;

public sealed class GetOrdersByCustomerHandler(IOrderRepository orderRepository)
    : IRequestHandler<GetOrdersByCustomerQuery, IReadOnlyList<OrderDto>>
{
    public async Task<IReadOnlyList<OrderDto>> Handle(
        GetOrdersByCustomerQuery query, CancellationToken ct)
    {
        var orders = await orderRepository.GetByCustomerAsync(CustomerId.Of(query.CustomerId), ct);
        return orders.Select(OrderDto.FromAggregate).ToList();
    }
}
```

---

## 4. Capa Infrastructure

### 4.1 DbContext

#### `ShopDemo.Orders.Infraestructure/Persistence/OrdersDbContext.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using ShopDemo.Orders.Domain.Aggregates;

namespace ShopDemo.Orders.Infraestructure.Persistence;

public sealed class OrdersDbContext(DbContextOptions<OrdersDbContext> options) : DbContext(options)
{
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(OrdersDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
```

### 4.2 EF Configuration

#### `ShopDemo.Orders.Infraestructure/Persistence/Configurations/OrderConfiguration.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.Entities;

namespace ShopDemo.Orders.Infraestructure.Persistence.Configurations;

public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("orders");
        builder.HasKey(o => o.Id);

        builder.Property(o => o.CreatedAt).IsRequired();
        builder.Property(o => o.LastUpdatedAt);

        builder.OwnsOne(o => o.CustomerId, ci =>
        {
            ci.Property(c => c.Value).HasColumnName("customer_id").IsRequired();
        });

        builder.OwnsOne(o => o.ShippingAddress, sa =>
        {
            sa.Property(a => a.Street).HasColumnName("ship_street").HasMaxLength(300).IsRequired();
            sa.Property(a => a.City).HasColumnName("ship_city").HasMaxLength(100).IsRequired();
            sa.Property(a => a.PostalCode).HasColumnName("ship_postal_code").HasMaxLength(20).IsRequired();
            sa.Property(a => a.Country).HasColumnName("ship_country").HasMaxLength(3).IsRequired();
        });

        builder.OwnsOne(o => o.Status, st =>
        {
            st.Property(s => s.Value).HasColumnName("status").HasMaxLength(20).IsRequired();
        });

        builder.OwnsOne(o => o.TotalAmount, money =>
        {
            money.Property(m => m.Amount).HasColumnName("total_amount").HasPrecision(18, 2);
            money.Property(m => m.Currency).HasColumnName("total_currency").HasMaxLength(3).IsRequired();
        });

        builder.OwnsMany(o => o.Lines, lines =>
        {
            lines.ToTable("order_lines");
            lines.WithOwner().HasForeignKey("OrderId");
            lines.HasKey(l => l.Id);

            lines.Property(l => l.ProductId).HasColumnName("product_id").IsRequired();
            lines.Property(l => l.ProductName).HasColumnName("product_name").HasMaxLength(200).IsRequired();

            lines.OwnsOne(l => l.UnitPrice, price =>
            {
                price.Property(p => p.Amount).HasColumnName("unit_price_amount").HasPrecision(18, 2);
                price.Property(p => p.Currency).HasColumnName("unit_price_currency").HasMaxLength(3);
            });

            lines.OwnsOne(l => l.Quantity, q =>
            {
                q.Property(x => x.Value).HasColumnName("quantity");
            });

            lines.OwnsOne(l => l.LineTotal, total =>
            {
                total.Property(t => t.Amount).HasColumnName("line_total_amount").HasPrecision(18, 2);
                total.Property(t => t.Currency).HasColumnName("line_total_currency").HasMaxLength(3);
            });
        });

        builder.Navigation(o => o.Lines).HasField("_lines");
        builder.Ignore(o => o.DomainEvents);
    }
}
```

### 4.3 Repository, UnitOfWork, DatabaseInitializer

#### `ShopDemo.Orders.Infraestructure/Persistence/OrderRepository.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Domain.ValueObjects;

namespace ShopDemo.Orders.Infraestructure.Persistence;

public sealed class OrderRepository(OrdersDbContext dbContext) : IOrderRepository
{
    public async Task<Order> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await dbContext.Orders
            .Include(o => o.Lines)
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

        return order ?? throw new KeyNotFoundException($"Order with id '{id}' was not found.");
    }

    public async Task<IEnumerable<Order>> GetAllAsync(CancellationToken cancellationToken = default)
        => await dbContext.Orders.AsNoTracking().Include(o => o.Lines).ToListAsync(cancellationToken);

    public async Task AddAsync(Order aggregate, CancellationToken cancellationToken = default)
        => await dbContext.Orders.AddAsync(aggregate, cancellationToken);

    public Task UpdateAsync(Order aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Orders.Update(aggregate);
        return Task.CompletedTask;
    }

    public Task DeleteAsync(Order aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Orders.Remove(aggregate);
        return Task.CompletedTask;
    }

    public async Task<IReadOnlyList<Order>> GetByCustomerAsync(
        CustomerId customerId, CancellationToken ct = default)
        => await dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Lines)
            .Where(o => o.CustomerId.Value == customerId.Value)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<Order>> GetByStatusAsync(
        OrderStatus status, int skip, int take, CancellationToken ct = default)
        => await dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Lines)
            .Where(o => o.Status.Value == status.Value)
            .OrderByDescending(o => o.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(ct);
}
```

#### `ShopDemo.Orders.Infraestructure/Persistence/UnitOfWork.cs`

```csharp
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Infraestructure.Persistence;

public sealed class UnitOfWork(OrdersDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
```

#### `ShopDemo.Orders.Infraestructure/Persistence/DatabaseInitializer.cs`

```csharp
using Npgsql;

namespace ShopDemo.Orders.Infraestructure.Persistence;

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

### 4.4 Messaging y DI

#### `ShopDemo.Orders.Infraestructure/Messaging/LoggingDomainEventPublisher.cs`

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

#### `ShopDemo.Orders.Infraestructure/DependencyInjection.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
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
        services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();

        return services;
    }
}
```

---

## 5. Capa API

### 5.1 Controller

#### `ShopDemo.Orders.Api/Controllers/OrdersController.cs`

```csharp
using MediatR;
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Orders.Application.Commands.CancelOrder;
using ShopDemo.Orders.Application.Commands.ConfirmOrder;
using ShopDemo.Orders.Application.Commands.PlaceOrder;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Queries.GetOrderById;
using ShopDemo.Orders.Application.Queries.GetOrdersByCustomer;

namespace ShopDemo.Orders.Api.Controllers;

[ApiController]
[Route("api/orders")]
public sealed class OrdersController(IMediator mediator) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<OrderDto>> Place(
        [FromBody] PlaceOrderCommand command, CancellationToken ct)
    {
        var order = await mediator.Send(command, ct);
        return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OrderDto>> GetById(Guid id, CancellationToken ct)
    {
        var order = await mediator.Send(new GetOrderByIdQuery(id), ct);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<OrderDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<OrderDto>>> GetByCustomer(
        [FromQuery] Guid customerId, CancellationToken ct)
    {
        var orders = await mediator.Send(new GetOrdersByCustomerQuery(customerId), ct);
        return Ok(orders);
    }

    [HttpPost("{id:guid}/confirm")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> Confirm(Guid id, CancellationToken ct)
    {
        var order = await mediator.Send(new ConfirmOrderCommand(id), ct);
        return Ok(order);
    }

    [HttpPost("{id:guid}/cancel")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> Cancel(
        Guid id, [FromBody] CancelOrderRequest request, CancellationToken ct)
    {
        var order = await mediator.Send(new CancelOrderCommand(id, request.Reason), ct);
        return Ok(order);
    }

    public sealed record CancelOrderRequest(string Reason);
}
```

### 5.2 Middleware

#### `ShopDemo.Orders.Api/Middleware/ExceptionHandlingMiddleware.cs`

```csharp
using System.Text.Json;
using FluentValidation;
using ShopDemo.Orders.Domain.Exceptions;

namespace ShopDemo.Orders.Api.Middleware;

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

            OrderDomainException domainException => (
                StatusCodes.Status400BadRequest,
                "Domain rule violation",
                domainException.Message),

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

### 5.3 Program.cs

#### `ShopDemo.Orders.Api/Program.cs`

```csharp
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi;
using ShopDemo.Orders.Api.Middleware;
using ShopDemo.Orders.Application.Commands.PlaceOrder;
using ShopDemo.Orders.Application.Common.Behaviors;
using ShopDemo.Orders.Infraestructure;
using ShopDemo.Orders.Infraestructure.Persistence;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ShopDemo Orders API",
        Version = "v1",
        Description = "Microservicio de gestión de pedidos"
    });
});

builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(PlaceOrderHandler).Assembly);
    cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
});

builder.Services.AddValidatorsFromAssemblyContaining<PlaceOrderValidator>();
builder.Services.AddOrdersInfrastructure(builder.Configuration);

var app = builder.Build();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

await DatabaseInitializer.EnsureCreatedAsync(connectionString);

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
    await dbContext.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "ShopDemo Orders API v1");
        options.RoutePrefix = "swagger";
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.MapControllers();

app.Run();
```

### 5.4 appsettings

#### `ShopDemo.Orders.Api/appsettings.json`

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5434;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123"
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

#### `ShopDemo.Orders.Api/appsettings.Development.json`

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5434;Database=ShopDemoOrders;Username=ShopDemo;Password=ShopDemo123"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

#### `ShopDemo.Orders.Api/Properties/launchSettings.json`

```json
{
  "$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "swagger",
      "applicationUrl": "http://localhost:5259",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

---

## 6. Docker

### 6.1 Dockerfile

#### `ShopDemo.Orders.Api/Dockerfile`

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj", "ShopDemo.Orders.Api/"]
COPY ["ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj", "ShopDemo.Orders.Application/"]
COPY ["ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj", "ShopDemo.Orders.Infraestructure/"]
COPY ["ShopDemo.Orders.Domain/ShopDemo.Orders.Domain.csproj", "ShopDemo.Orders.Domain/"]
COPY ["ShopDemo.Shared/ShopDemo.Shared.csproj", "ShopDemo.Shared/"]

RUN dotnet restore "ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj"

COPY . .
WORKDIR "/src/ShopDemo.Orders.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Orders.Api.dll"]
```

### 6.2 docker-compose.yml

#### `ShopDemo.Orders.Api/docker-compose.yml`

```yaml
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
    depends_on:
      orders-db:
        condition: service_healthy

volumes:
  orders-db-data:
```

### 6.3 Script de inicialización PostgreSQL

#### `ShopDemo.Orders.Api/docker/postgres/init/01-init-shopdemoorders.sql`

```sql
\connect ShopDemoOrders

GRANT ALL ON SCHEMA public TO "ShopDemo";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "ShopDemo";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "ShopDemo";
```

---

## 7. Migraciones y ejecución

### 7.1 Crear migración inicial

```bash
cd I:\Curso\ShopDemo

dotnet ef migrations add InitialCreate \
  --project ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj \
  --startup-project ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj \
  --output-dir Persistence/Migrations
```

### 7.2 Ejecutar localmente

```bash
# Levantar solo PostgreSQL
cd ShopDemo.Orders.Api
docker compose up -d orders-db

# Ejecutar API
dotnet run --project ShopDemo.Orders.Api
```

### 7.3 Ejecutar con Docker (todo el stack)

```bash
cd ShopDemo.Orders.Api
docker compose down
docker compose up -d --build
```

### 7.4 Verificar compilación

```bash
dotnet build ShopDemo.slnx
```

---

## 8. Pruebas manuales

### 8.1 Crear pedido

```http
POST http://localhost:8002/api/orders
Content-Type: application/json

{
  "customerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "shippingAddress": {
    "street": "Av. Reforma 123",
    "city": "Ciudad de México",
    "postalCode": "06600",
    "country": "MX"
  },
  "lines": [
    {
      "productId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "productName": "Laptop Pro",
      "unitPrice": 1299.99,
      "currency": "MXN",
      "quantity": 1
    }
  ]
}
```

### 8.2 Consultar pedido

```http
GET http://localhost:8002/api/orders/{orderId}
```

### 8.3 Confirmar pedido

```http
POST http://localhost:8002/api/orders/{orderId}/confirm
```

### 8.4 Cancelar pedido

```http
POST http://localhost:8002/api/orders/{orderId}/cancel
Content-Type: application/json

{
  "reason": "Cliente solicitó cancelación"
}
```

### 8.5 Listar por cliente

```http
GET http://localhost:8002/api/orders?customerId=3fa85f64-5717-4562-b3fc-2c963f66afa6
```

### 8.6 Verificar en pgAdmin

| Campo | Valor |
|---|---|
| Host | `localhost` |
| Puerto | `5434` |
| Usuario | `ShopDemo` |
| Contraseña | `ShopDemo123` |
| Base de datos | `ShopDemoOrders` |

Tablas esperadas: `orders`, `order_lines`, `__EFMigrationsHistory`.

---

## Respuestas a preguntas de reflexión

1. **OrderLine es Entity** porque tiene identidad propia (`Id`) y persiste dentro del agregado Order.
2. La regla "al menos 1 línea" vive en el **Aggregate `Order.Place()`**, no en el Handler.
3. El **Aggregate** calcula el total iterando líneas; el Handler solo orquesta.
4. El **snapshot** evita acoplamiento con Catalog y preserva el precio histórico del pedido.
5. Sin Outbox, un fallo de red tras `SaveChanges` dejaría datos persistidos sin evento publicado (inconsistencia).

---

## Archivos .csproj de referencia

### `ShopDemo.Orders.Domain.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <ProjectReference Include="..\ShopDemo.Shared\ShopDemo.Shared.csproj" />
  </ItemGroup>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
```

### `ShopDemo.Orders.Application.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="FluentValidation" Version="12.1.1" />
    <PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="12.1.1" />
    <PackageReference Include="MediatR" Version="14.1.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\ShopDemo.Orders.Domain\ShopDemo.Orders.Domain.csproj" />
  </ItemGroup>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
```

### `ShopDemo.Orders.Infraestructure.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="10.0.0" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\ShopDemo.Orders.Application\ShopDemo.Orders.Application.csproj" />
    <ProjectReference Include="..\ShopDemo.Orders.Domain\ShopDemo.Orders.Domain.csproj" />
    <ProjectReference Include="..\ShopDemo.Shared\ShopDemo.Shared.csproj" />
  </ItemGroup>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
```

### `ShopDemo.Orders.Api.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Swashbuckle.AspNetCore" Version="10.2.1" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\ShopDemo.Orders.Infraestructure\ShopDemo.Orders.Infraestructure.csproj" />
    <ProjectReference Include="..\ShopDemo.Orders.Application\ShopDemo.Orders.Application.csproj" />
  </ItemGroup>
</Project>
```
