namespace ShopDemo.Shared.Messaging;

/// <summary>
/// Formato común para transportar eventos entre microservicios vía Azure Event Hubs.
/// </summary>
public sealed record IntegrationEventEnvelope(
    string EventType,
    Guid EventId,
    DateTimeOffset OccurredOn,
    string Source,
    string PayloadJson);
