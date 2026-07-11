using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Queries.GetOrdersByCustomer;

public sealed record GetOrdersByCustomerQuery(Guid CustomerId) : IRequest<IReadOnlyList<OrderDto>>;
