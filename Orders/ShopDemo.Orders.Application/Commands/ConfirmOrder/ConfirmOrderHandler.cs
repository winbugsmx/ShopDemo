using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Commands.ConfirmOrder;

public sealed class ConfirmOrderHandler(
    IOrderRepository orderRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher,
    IInventoryService inventoryService
) : IRequestHandler<ConfirmOrderCommand, OrderDto>
{
    public async Task<OrderDto> Handle(ConfirmOrderCommand command, CancellationToken ct)
    {
        var order = await orderRepository.GetByIdAsync(command.OrderId, ct);

        var lines = order.Lines
            .Select(l => new InventoryLineRequest(l.ProductId, l.Quantity.Value))
            .ToList();

        await inventoryService.ReserveStockAsync(order.Id, lines, ct);

        order.Confirm();

        await orderRepository.UpdateAsync(order, ct);
        await unitOfWork.SaveChangesAsync(ct);

        await eventPublisher.PublishAsync(order.DomainEvents, ct);
        order.ClearDomainEvents();

        return OrderDto.FromAggregate(order);
    }
}
