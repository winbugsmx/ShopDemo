using ShopDemo.Inventory.Application.DTOs;

namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada (driving): registrar stock de un producto.
/// </summary>
public interface IRegisterStockUseCase
{
    Task<StockEntryDto> ExecuteAsync(RegisterStockRequest request, CancellationToken ct = default);
}

public sealed record RegisterStockRequest(Guid ProductId, string ProductName, int Units);
