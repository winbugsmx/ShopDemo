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
