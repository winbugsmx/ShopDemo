using Microsoft.EntityFrameworkCore;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Aggregates;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

/// <summary>
/// Adaptador driven: implementa IStockEntryRepository con EF Core.
/// </summary>
public sealed class StockEntryRepository(InventoryDbContext dbContext) : IStockEntryRepository
{
    public Task<StockEntry?> GetByProductIdAsync(Guid productId, CancellationToken ct = default)
        => dbContext.StockEntries.FirstOrDefaultAsync(s => s.Id == productId, ct);

    public Task<bool> ExistsAsync(Guid productId, CancellationToken ct = default)
        => dbContext.StockEntries.AnyAsync(s => s.Id == productId, ct);

    public async Task AddAsync(StockEntry entry, CancellationToken ct = default)
        => await dbContext.StockEntries.AddAsync(entry, ct);

    public Task UpdateAsync(StockEntry entry, CancellationToken ct = default)
    {
        dbContext.StockEntries.Update(entry);
        return Task.CompletedTask;
    }
}
