using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: reserva stock para las líneas de un pedido confirmado.
/// Invocado por Orders API vía HTTP.
/// </summary>
public sealed class ReserveStockUseCase(
    IStockEntryRepository repository,
    IUnitOfWork unitOfWork,
    IIntegrationEventPublisher eventPublisher
) : IReserveStockUseCase
{
    public async Task ExecuteAsync(ReserveStockRequest request, CancellationToken ct = default)
    {
        foreach (var line in request.Lines)
        {
            var entry = await repository.GetByProductIdAsync(line.ProductId, ct)
                ?? throw new InventoryDomainException(
                    $"No stock entry found for product '{line.ProductId}'.");

            entry.Reserve(line.Quantity, request.OrderId);
            await repository.UpdateAsync(entry, ct);
            await eventPublisher.PublishAsync(entry.DomainEvents, ct);
            entry.ClearDomainEvents();
        }

        await unitOfWork.SaveChangesAsync(ct);
    }
}
