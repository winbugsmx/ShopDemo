using System.Net.Http.Json;
using Microsoft.Extensions.Logging;
using ShopDemo.Orders.Application.Ports;

namespace ShopDemo.Orders.Infraestructure.Integrations;

/// <summary>
/// Adaptador HTTP hacia Inventory API (arquitectura hexagonal — driven adapter en Orders).
/// </summary>
public sealed class InventoryHttpClient(
    HttpClient httpClient,
    ILogger<InventoryHttpClient> logger) : IInventoryService
{
    public async Task ReserveStockAsync(
        Guid orderId,
        IReadOnlyList<InventoryLineRequest> lines,
        CancellationToken ct = default)
    {
        var payload = new
        {
            orderId,
            lines = lines.Select(l => new { productId = l.ProductId, quantity = l.Quantity })
        };

        logger.LogInformation("Reserving stock in Inventory for order {OrderId}", orderId);

        var response = await httpClient.PostAsJsonAsync("api/inventory/reservations", payload, ct);
        response.EnsureSuccessStatusCode();
    }

    public async Task ReleaseStockAsync(
        Guid orderId,
        IReadOnlyList<InventoryLineRequest> lines,
        CancellationToken ct = default)
    {
        var payload = new
        {
            orderId,
            lines = lines.Select(l => new { productId = l.ProductId, quantity = l.Quantity })
        };

        logger.LogInformation("Releasing stock in Inventory for order {OrderId}", orderId);

        var response = await httpClient.PostAsJsonAsync("api/inventory/reservations/release", payload, ct);
        response.EnsureSuccessStatusCode();
    }
}
