using Microsoft.AspNetCore.Mvc;
using ShopDemo.Inventory.Application.Ports.Inbound;

namespace ShopDemo.Inventory.Api.Adapters.Http;

/// <summary>
/// Adaptador driving: endpoints de reserva/liberación invocados por Orders API.
/// </summary>
[ApiController]
[Route("api/inventory/reservations")]
public sealed class ReservationsController(
    IReserveStockUseCase reserveStock,
    IReleaseStockUseCase releaseStock) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Reserve(
        [FromBody] ReserveStockBody body, CancellationToken ct)
    {
        await reserveStock.ExecuteAsync(
            new ReserveStockRequest(
                body.OrderId,
                body.Lines.Select(l => new ReserveStockLineRequest(l.ProductId, l.Quantity)).ToList()),
            ct);

        return NoContent();
    }

    [HttpPost("release")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Release(
        [FromBody] ReleaseStockBody body, CancellationToken ct)
    {
        await releaseStock.ExecuteAsync(
            new ReleaseStockRequest(
                body.OrderId,
                body.Lines.Select(l => new ReleaseStockLineRequest(l.ProductId, l.Quantity)).ToList()),
            ct);

        return NoContent();
    }

    public sealed record ReserveStockBody(Guid OrderId, List<LineBody> Lines);
    public sealed record ReleaseStockBody(Guid OrderId, List<LineBody> Lines);
    public sealed record LineBody(Guid ProductId, int Quantity);
}
