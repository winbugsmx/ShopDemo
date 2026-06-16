using ShopDemo.Orders.Domain.Aggregates;

namespace ShopDemo.Orders.Application.DTOs;

public sealed record OrderDto(
    Guid Id,
    Guid CustomerId,
    string Status,
    decimal TotalAmount,
    string Currency,
    ShippingAddressDto ShippingAddress,
    IReadOnlyList<OrderLineDto> Lines,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastUpdatedAt
)
{
    public static OrderDto FromAggregate(Order order) => new(
        order.Id,
        order.CustomerId.Value,
        order.Status.Value,
        order.TotalAmount.Amount,
        order.TotalAmount.Currency,
        new ShippingAddressDto(
            order.ShippingAddress.Street,
            order.ShippingAddress.City,
            order.ShippingAddress.PostalCode,
            order.ShippingAddress.Country),
        order.Lines.Select(l => new OrderLineDto(
            l.Id,
            l.ProductId,
            l.ProductName,
            l.UnitPrice.Amount,
            l.UnitPrice.Currency,
            l.Quantity.Value,
            l.LineTotal.Amount)).ToList(),
        order.CreatedAt,
        order.LastUpdatedAt);
}

public sealed record ShippingAddressDto(
    string Street,
    string City,
    string PostalCode,
    string Country
);
