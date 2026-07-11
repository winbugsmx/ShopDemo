using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Events;

public sealed record StockDepletedDomainEvent(
    Guid ProductId,
    string ProductName
) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTimeOffset OccurredOn { get; } = DateTimeOffset.UtcNow;
}