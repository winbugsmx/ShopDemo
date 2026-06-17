using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Infraestructure.Persistence;

public sealed class UnitOfWork(OrdersDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
