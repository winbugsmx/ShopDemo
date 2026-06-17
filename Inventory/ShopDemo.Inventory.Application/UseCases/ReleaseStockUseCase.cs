using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: libera stock previamente reservado al cancelar un pedido.
/// </summary>
public sealed class ReleaseStockUseCase(
    IStockEntryRepository repository,
    IUnitOfWork unitOfWork,
    IIntegrationEventPublisher eventPublisher
) : IReleaseStockUseCase
{
    public async Task ExecuteAsync(ReleaseStockRequest request, CancellationToken ct = default)
    {
        foreach (var line in request.Lines)
        {
            var entry = await repository.GetByProductIdAsync(line.ProductId, ct)
                ?? throw new InventoryDomainException(
                    $"No stock entry found for product '{line.ProductId}'.");

            entry.Release(line.Quantity, request.OrderId);
            await repository.UpdateAsync(entry, ct);
            await eventPublisher.PublishAsync(entry.DomainEvents, ct);
            entry.ClearDomainEvents();
        }

        await unitOfWork.SaveChangesAsync(ct);
    }
}
