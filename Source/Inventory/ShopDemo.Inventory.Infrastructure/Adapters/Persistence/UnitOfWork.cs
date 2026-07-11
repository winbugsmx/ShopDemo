using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

public sealed class UnitOfWork(InventoryDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
