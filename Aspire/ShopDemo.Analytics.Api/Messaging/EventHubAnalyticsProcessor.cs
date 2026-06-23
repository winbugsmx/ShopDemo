using System.Text;
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using ShopDemo.Analytics.Api.Services;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Analytics.Api.Messaging;

/// <summary>
/// Consumidor de Analytics: observa todos los eventos del bus (consumer group analytics-service).
/// No ejecuta lógica de negocio — solo registra eventos para consulta.
/// </summary>
public sealed class EventHubAnalyticsProcessor : BackgroundService
{
    private readonly EventProcessorClient _processor;
    private readonly InMemoryEventStore _eventStore;
    private readonly ILogger<EventHubAnalyticsProcessor> _logger;

    public EventHubAnalyticsProcessor(
        IConfiguration configuration,
        InMemoryEventStore eventStore,
        ILogger<EventHubAnalyticsProcessor> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Analytics.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Analytics.");

        var checkpointConnection = configuration["EventHubs:CheckpointStorageConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:CheckpointStorageConnectionString is not configured for Analytics.");

        var checkpointContainer = configuration["EventHubs:CheckpointContainerName"]
            ?? "analytics-checkpoints";

        var consumerGroup = configuration["EventHubs:ConsumerGroup"]
            ?? "analytics-service";

        _processor = new EventProcessorClient(
            new BlobContainerClient(checkpointConnection, checkpointContainer),
            consumerGroup,
            connectionString,
            eventHubName);

        _processor.ProcessEventAsync += OnProcessEventAsync;
        _processor.ProcessErrorAsync += OnProcessErrorAsync;
        _eventStore = eventStore;
        _logger = logger;
    }

    private async Task OnProcessEventAsync(ProcessEventArgs args)
    {
        var body = Encoding.UTF8.GetString(args.Data.Body.ToArray());
        var envelope = JsonSerializer.Deserialize<IntegrationEventEnvelope>(body);

        if (envelope is not null)
        {
            _eventStore.Add(new StoredEvent(
                envelope.EventType,
                envelope.EventId,
                envelope.OccurredOn,
                envelope.Source,
                envelope.PayloadJson,
                DateTimeOffset.UtcNow));

            _logger.LogInformation(
                "Analytics observed {EventType} from {Source} ({EventId})",
                envelope.EventType,
                envelope.Source,
                envelope.EventId);
        }

        await args.UpdateCheckpointAsync(args.CancellationToken);
    }

    private Task OnProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(
            args.Exception,
            "Analytics Event Hubs processor error. Partition={PartitionId}",
            args.PartitionId);

        return Task.CompletedTask;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Analytics Event Hubs consumer started (group: analytics-service)");
        return _processor.StartProcessingAsync(stoppingToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
        _logger.LogInformation("Analytics Event Hubs consumer stopped");
    }
}
