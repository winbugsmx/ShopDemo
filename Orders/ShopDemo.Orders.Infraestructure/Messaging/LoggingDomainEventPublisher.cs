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
