using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Repositories;

public interface IOrderRepository : IRepository<Order, Guid>
{
    Task<IReadOnlyList<Order>> GetByCustomerAsync(
        CustomerId customerId, CancellationToken ct = default);

    Task<IReadOnlyList<Order>> GetByStatusAsync(
        OrderStatus status, int skip, int take, CancellationToken ct = default);
}
