using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Queries.GetOrderById;

public sealed record GetOrderByIdQuery(Guid OrderId) : IRequest<OrderDto?>;
