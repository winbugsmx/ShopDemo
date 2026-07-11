using ShopDemo.Inventory.Application.DTOs;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Domain.Aggregates;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Inventory.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Application.UseCases;

/// <summary>
/// Caso de uso: registra stock inicial o reabastece un producto existente.
/// Implementa el puerto de entrada IRegisterStockUseCase.
/// </summary>
public sealed class RegisterStockUseCase(
    IStockEntryRepository repository,
    IUnitOfWork unitOfWork,
    IIntegrationEventPublisher eventPublisher
) : IRegisterStockUseCase
{
    public async Task<StockEntryDto> ExecuteAsync(RegisterStockRequest request, CancellationToken ct = default)
    {
        var product = ProductReference.Create(request.ProductId, request.ProductName);
        var units = StockQuantity.Of(request.Units);

        var existing = await repository.GetByProductIdAsync(request.ProductId, ct);

        if (existing is null)
        {
            var entry = StockEntry.Register(product, units);
            await repository.AddAsync(entry, ct);
            await unitOfWork.SaveChangesAsync(ct);
            await eventPublisher.PublishAsync(entry.DomainEvents, ct);
            entry.ClearDomainEvents();
            return StockEntryDto.FromAggregate(entry);
        }

        existing.Replenish(request.Units);
        await repository.UpdateAsync(existing, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return StockEntryDto.FromAggregate(existing);
    }
}
