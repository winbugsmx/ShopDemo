using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Domain.Repositories;

namespace ShopDemo.Orders.Application.Queries.GetOrderById;

public sealed class GetOrderByIdHandler(IOrderRepository orderRepository)
    : IRequestHandler<GetOrderByIdQuery, OrderDto?>
{
    public async Task<OrderDto?> Handle(GetOrderByIdQuery query, CancellationToken ct)
    {
        try
        {
            var order = await orderRepository.GetByIdAsync(query.OrderId, ct);
            return OrderDto.FromAggregate(order);
        }
        catch (KeyNotFoundException)
        {
            return null;
        }
    }
}
