using ShopDemo.Inventory.Application.DTOs;

namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada: consultar stock por ProductId.
/// </summary>
public interface IGetStockByProductUseCase
{
    Task<StockEntryDto?> ExecuteAsync(Guid productId, CancellationToken ct = default);
}
