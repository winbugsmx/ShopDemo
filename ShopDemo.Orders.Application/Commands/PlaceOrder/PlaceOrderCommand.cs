using MediatR;
using ShopDemo.Orders.Application.DTOs;

namespace ShopDemo.Orders.Application.Commands.PlaceOrder;

public sealed record PlaceOrderCommand(
    Guid CustomerId,
    ShippingAddressDto ShippingAddress,
    IReadOnlyList<PlaceOrderLineDto> Lines
) : IRequest<OrderDto>;

public sealed record PlaceOrderLineDto(
    Guid ProductId,
    string ProductName,
    decimal UnitPrice,
    string Currency,
    int Quantity
);
