using MediatR;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Application.Commands.CancelOrder;

public sealed class CancelOrderHandler(
    IOrderRepository orderRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher,
    IInventoryService inventoryService
) : IRequestHandler<CancelOrderCommand, OrderDto>
{
    public async Task<OrderDto> Handle(CancelOrderCommand command, CancellationToken ct)
    {
        var order = await orderRepository.GetByIdAsync(command.OrderId, ct);

        if (order.Status.IsConfirmed)
        {
            var lines = order.Lines
                .Select(l => new InventoryLineRequest(l.ProductId, l.Quantity.Value))
                .ToList();

            await inventoryService.ReleaseStockAsync(order.Id, lines, ct);
        }

        order.Cancel(command.Reason);

        await orderRepository.UpdateAsync(order, ct);
        await unitOfWork.SaveChangesAsync(ct);

        await eventPublisher.PublishAsync(order.DomainEvents, ct);
        order.ClearDomainEvents();

        return OrderDto.FromAggregate(order);
    }
}
