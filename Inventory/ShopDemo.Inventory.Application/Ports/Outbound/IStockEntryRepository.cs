using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Application.Ports.Outbound;

/// <summary>
/// Puerto de salida (driven): persistencia del agregado StockEntry.
/// </summary>
public interface IStockEntryRepository
{
    Task<StockEntry?> GetByProductIdAsync(Guid productId, CancellationToken ct = default);
    Task<bool> ExistsAsync(Guid productId, CancellationToken ct = default);
    Task AddAsync(StockEntry entry, CancellationToken ct = default);
    Task UpdateAsync(StockEntry entry, CancellationToken ct = default);
}
