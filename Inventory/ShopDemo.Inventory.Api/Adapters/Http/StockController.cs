using Microsoft.AspNetCore.Mvc;
using ShopDemo.Inventory.Application.Ports.Inbound;

namespace ShopDemo.Inventory.Api.Adapters.Http;

/// <summary>
/// Adaptador driving (HTTP): expone operaciones de stock delegando a puertos de entrada.
/// </summary>
[ApiController]
[Route("api/inventory")]
public sealed class StockController(
    IRegisterStockUseCase registerStock,
    IGetStockByProductUseCase getStock) : ControllerBase
{
    [HttpPost("stock")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    public async Task<IActionResult> RegisterStock(
        [FromBody] RegisterStockBody body, CancellationToken ct)
    {
        var result = await registerStock.ExecuteAsync(
            new RegisterStockRequest(body.ProductId, body.ProductName, body.Units), ct);

        return CreatedAtAction(nameof(GetStock), new { productId = result.ProductId }, result);
    }

    [HttpGet("{productId:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetStock(Guid productId, CancellationToken ct)
    {
        var result = await getStock.ExecuteAsync(productId, ct);
        return result is null ? NotFound() : Ok(result);
    }

    public sealed record RegisterStockBody(Guid ProductId, string ProductName, int Units);
}
