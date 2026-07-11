using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.Ports.Outbound;

/// <summary>
/// Puerto de salida: publicar eventos de integración hacia el bus de mensajería.
/// </summary>
public interface IIntegrationEventPublisher
{
    Task PublishAsync(IReadOnlyCollection<IDomainEvent> events, CancellationToken ct = default);
}
