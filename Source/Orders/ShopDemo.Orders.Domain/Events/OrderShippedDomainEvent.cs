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
