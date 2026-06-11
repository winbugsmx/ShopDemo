using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure.Persistence;

public sealed class UnitOfWork(CatalogDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
