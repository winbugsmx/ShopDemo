using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Aggregates;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Commands.PlaceOrder;

public sealed class PlaceOrderHandler(
    IOrderRepository orderRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher
) : IRequestHandler<PlaceOrderCommand, OrderDto>
{
    public async Task<OrderDto> Handle(PlaceOrderCommand command, CancellationToken ct)
    {
        var customerId = CustomerId.Of(command.CustomerId);
        var address = ShippingAddress.Create(
            command.ShippingAddress.Street,
            command.ShippingAddress.City,
            command.ShippingAddress.PostalCode,
            command.ShippingAddress.Country);

        var lines = command.Lines.Select(l => (
            l.ProductId,
            l.ProductName,
            Money.Of(l.UnitPrice, l.Currency),
            Quantity.Of(l.Quantity)));

        var order = Order.Place(customerId, address, lines);

        await orderRepository.AddAsync(order, ct);
        await unitOfWork.SaveChangesAsync(ct);

        await eventPublisher.PublishAsync(order.DomainEvents, ct);
        order.ClearDomainEvents();

        return OrderDto.FromAggregate(order);
    }
}
