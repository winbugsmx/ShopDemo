using ShopDemo.Inventory.Application.DTOs;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: consulta el stock disponible de un producto.
/// </summary>
public sealed class GetStockByProductUseCase(IStockEntryRepository repository)
    : IGetStockByProductUseCase
{
    public async Task<StockEntryDto?> ExecuteAsync(Guid productId, CancellationToken ct = default)
    {
        var entry = await repository.GetByProductIdAsync(productId, ct);
        return entry is null ? null : StockEntryDto.FromAggregate(entry);
    }
}
