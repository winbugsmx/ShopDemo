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
