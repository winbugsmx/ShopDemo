using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Commands.CancelOrder;

public sealed record CancelOrderCommand(Guid OrderId, string Reason) : IRequest<OrderDto>;
