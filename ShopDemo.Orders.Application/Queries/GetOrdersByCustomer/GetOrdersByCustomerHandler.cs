using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Domain.ValueObjects;

namespace ShopDemo.Orders.Application.Queries.GetOrdersByCustomer;

public sealed class GetOrdersByCustomerHandler(IOrderRepository orderRepository)
    : IRequestHandler<GetOrdersByCustomerQuery, IReadOnlyList<OrderDto>>
{
    public async Task<IReadOnlyList<OrderDto>> Handle(
        GetOrdersByCustomerQuery query, CancellationToken ct)
    {
        var orders = await orderRepository.GetByCustomerAsync(CustomerId.Of(query.CustomerId), ct);
        return orders.Select(OrderDto.FromAggregate).ToList();
    }
}
