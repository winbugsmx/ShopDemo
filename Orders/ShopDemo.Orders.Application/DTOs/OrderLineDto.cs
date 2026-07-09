namespace ShopDemo.Orders.Application.DTOs;

public sealed record OrderLineDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    decimal UnitPrice,
    string Currency,
    int Quantity,
    decimal LineTotal
);
