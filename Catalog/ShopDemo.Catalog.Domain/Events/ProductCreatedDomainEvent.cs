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





