using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Application.Ports;

/// <summary>
/// Puerto hacia la infraestructura de mensajería.
/// Application define el contrato; Infrastructure (Event Hubs) lo implementa.
/// </summary>
public interface IDomainEventPublisher
{
    Task PublishAsync(IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken ct = default);
}
