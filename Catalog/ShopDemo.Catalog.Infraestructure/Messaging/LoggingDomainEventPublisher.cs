using Microsoft.Extensions.Logging;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure.Messaging;

/// <summary>
/// Implementación de desarrollo que registra eventos en logs.
/// Sustituir por Event Hubs u otro broker en producción.
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
