using System.Text;
using System.Text.Json;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Shared.Messaging;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Messaging;

/// <summary>
/// Consumidor de Inventory: escucha eventos de Catalog desde Event Hubs.
/// Ejemplo del curso: auto-registra stock cuando llega ProductCreatedDomainEvent.
/// </summary>
public sealed class CatalogEventsProcessor : BackgroundService
{
    private readonly EventProcessorClient _processor;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<CatalogEventsProcessor> _logger;

    public CatalogEventsProcessor(
        IConfiguration configuration,
        IServiceScopeFactory scopeFactory,
        ILogger<CatalogEventsProcessor> logger)
    {
        var connectionString = configuration["EventHubs:ConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:ConnectionString is not configured for Inventory consumer.");

        var eventHubName = configuration["EventHubs:EventHubName"]
            ?? throw new InvalidOperationException(
                "EventHubs:EventHubName is not configured for Inventory consumer.");

        var checkpointConnection = configuration["EventHubs:CheckpointStorageConnectionString"]
            ?? throw new InvalidOperationException(
                "EventHubs:CheckpointStorageConnectionString is not configured for Inventory consumer.");

        var checkpointContainer = configuration["EventHubs:CheckpointContainerName"]
            ?? "inventory-checkpoints";

        var consumerGroup = configuration["EventHubs:ConsumerGroup"]
            ?? "inventory-service";

        _processor = new EventProcessorClient(
            new BlobContainerClient(checkpointConnection, checkpointContainer),
            consumerGroup,
            connectionString,
            eventHubName);

        _processor.ProcessEventAsync += OnProcessEventAsync;
        _processor.ProcessErrorAsync += OnProcessErrorAsync;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    private async Task OnProcessEventAsync(ProcessEventArgs args)
    {
        var body = Encoding.UTF8.GetString(args.Data.Body.ToArray());
        var envelope = JsonSerializer.Deserialize<IntegrationEventEnvelope>(body);

        if (envelope is null)
        {
            await args.UpdateCheckpointAsync(args.CancellationToken);
            return;
        }

        if (envelope.Source == "catalog"
            && envelope.EventType == "ProductCreatedDomainEvent")
        {
            var payload = JsonSerializer.Deserialize<ProductCreatedPayload>(envelope.PayloadJson);

            if (payload is not null)
            {
                using var scope = _scopeFactory.CreateScope();
                var registerStock = scope.ServiceProvider
                    .GetRequiredService<IRegisterStockUseCase>();

                await registerStock.ExecuteAsync(
                    new RegisterStockRequest(
                        payload.ProductId,
                        payload.Name,
                        payload.InitialStock),
                    args.CancellationToken);

                _logger.LogInformation(
                    "Inventory auto-registered stock for product {ProductId} from Event Hubs",
                    payload.ProductId);
            }
        }

        await args.UpdateCheckpointAsync(args.CancellationToken);
    }

    private Task OnProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(
            args.Exception,
            "Inventory Event Hubs processor error. Partition={PartitionId}, Operation={Operation}",
            args.PartitionId,
            args.Operation);

        return Task.CompletedTask;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Inventory Event Hubs consumer started");
        return _processor.StartProcessingAsync(stoppingToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
        _logger.LogInformation("Inventory Event Hubs consumer stopped");
    }

    private sealed record ProductCreatedPayload(
        Guid ProductId,
        string Name,
        decimal Price,
        string Currency,
        int InitialStock,
        string Category);
}
