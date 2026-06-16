using Microsoft.EntityFrameworkCore;
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Domain.ValueObjects;

namespace ShopDemo.Orders.Infraestructure.Persistence;

public sealed class OrderRepository(OrdersDbContext dbContext) : IOrderRepository
{
    public async Task<Order> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await dbContext.Orders
            .Include(o => o.Lines)
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

        return order ?? throw new KeyNotFoundException($"Order with id '{id}' was not found.");
    }

    public async Task<IEnumerable<Order>> GetAllAsync(CancellationToken cancellationToken = default)
        => await dbContext.Orders.AsNoTracking().Include(o => o.Lines).ToListAsync(cancellationToken);

    public async Task AddAsync(Order aggregate, CancellationToken cancellationToken = default)
        => await dbContext.Orders.AddAsync(aggregate, cancellationToken);

    public Task UpdateAsync(Order aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Orders.Update(aggregate);
        return Task.CompletedTask;
    }

    public Task DeleteAsync(Order aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Orders.Remove(aggregate);
        return Task.CompletedTask;
    }

    public async Task<IReadOnlyList<Order>> GetByCustomerAsync(
        CustomerId customerId, CancellationToken ct = default)
        => await dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Lines)
            .Where(o => o.CustomerId.Value == customerId.Value)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<Order>> GetByStatusAsync(
        OrderStatus status, int skip, int take, CancellationToken ct = default)
        => await dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Lines)
            .Where(o => o.Status.Value == status.Value)
            .OrderByDescending(o => o.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(ct);
}
