using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Events;
using ShopDemo.Shared.Domain;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Orders.Infraestructure.Messaging;

/// <summary>
/// Adaptador de Orders: publica Domain Events al Event Hub de Azure.
/// Sustituye a LoggingDomainEventPublisher cuando EventHubs:Enabled = true.
/// </summary>
public sealed class EventHubsDomainEventPublisher : IDomainEventPublisher, IAsyncDisposable
{
    private readonly EventHubProducerClient _producer;
    private readonly ILogger<EventHubsDomainEventPublisher> _logger;

    public EventHubsDomainEventPublisher(
        IConfiguration configuration,
        ILogger<EventHubsDomainEventPublisher> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Orders.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Orders.");

        _producer = new EventHubProducerClient(connectionString, eventHubName);
        _logger = logger;
    }

    public async Task PublishAsync(
        IReadOnlyCollection<IDomainEvent> domainEvents,
        CancellationToken ct = default)
    {
        foreach (var domainEvent in domainEvents)
        {
            var envelope = new IntegrationEventEnvelope(
                EventType: domainEvent.GetType().Name,
                EventId: domainEvent.EventId,
                OccurredOn: domainEvent.OccurredOn,
                Source: "orders",
                PayloadJson: JsonSerializer.Serialize(domainEvent, domainEvent.GetType()));

            var partitionKey = GetPartitionKey(domainEvent);
            var eventBody = new EventData(JsonSerializer.SerializeToUtf8Bytes(envelope));

            using var batch = await _producer.CreateBatchAsync(
                new CreateBatchOptions { PartitionKey = partitionKey }, ct);

            if (!batch.TryAdd(eventBody))
                throw new InvalidOperationException(
                    $"Orders event '{envelope.EventType}' is too large for an Event Hubs batch.");

            await _producer.SendAsync(batch, ct);

            _logger.LogInformation(
                "Orders published {EventType} ({EventId}) to Event Hubs",
                envelope.EventType,
                envelope.EventId);
        }
    }

    private static string GetPartitionKey(IDomainEvent domainEvent) => domainEvent switch
    {
        OrderPlacedDomainEvent e => e.OrderId.ToString(),
        OrderConfirmedDomainEvent e => e.OrderId.ToString(),
        OrderCancelledDomainEvent e => e.OrderId.ToString(),
        OrderShippedDomainEvent e => e.OrderId.ToString(),
        _ => domainEvent.EventId.ToString()
    };

    public async ValueTask DisposeAsync() => await _producer.DisposeAsync();
}
