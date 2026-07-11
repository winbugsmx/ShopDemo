using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Ports;

public interface IDomainEventPublisher
{
    Task PublishAsync(IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken ct = default);
}
