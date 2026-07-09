using ShopDemo.Inventory.Domain.Events;
using ShopDemo.Inventory.Domain.Exceptions;
using ShopDemo.Inventory.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.Aggregates;

/// <summary>
/// Agregado raíz de inventario. El Id coincide con ProductId de Catalog.
/// </summary>
public sealed class StockEntry : AggregateRoot<Guid>
{
    public string ProductName { get; private set; } = string.Empty;
    public StockQuantity AvailableUnits { get; private set; } = StockQuantity.Zero;
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset? LastUpdatedAt { get; private set; }

    private StockEntry() { }

    public static StockEntry Register(ProductReference product, StockQuantity initialUnits)
    {
        var entry = new StockEntry
        {
            Id = product.ProductId,
            ProductName = product.ProductName,
            AvailableUnits = initialUnits,
            CreatedAt = DateTimeOffset.UtcNow
        };

        entry.RaiseDomainEvent(new StockEntryRegisteredDomainEvent(
            entry.Id, entry.ProductName, entry.AvailableUnits.Value));

        return entry;
    }

    public void Replenish(int units)
    {
        if (units <= 0)
            throw new InventoryDomainException("Replenish units must be greater than zero.");

        AvailableUnits = AvailableUnits.Increase(units);
        MarkUpdated();
    }

    public void Reserve(int units, Guid orderId)
    {
        if (units <= 0)
            throw new InventoryDomainException("Reserve units must be greater than zero.");

        var previous = AvailableUnits.Value;
        AvailableUnits = AvailableUnits.Decrease(units);
        MarkUpdated();

        RaiseDomainEvent(new StockReservedDomainEvent(Id, orderId, units, AvailableUnits.Value));

        if (AvailableUnits.Value == 0)
            RaiseDomainEvent(new StockDepletedDomainEvent(Id, ProductName));
    }

    public void Release(int units, Guid orderId)
    {
        if (units <= 0)
            throw new InventoryDomainException("Release units must be greater than zero.");

        AvailableUnits = AvailableUnits.Increase(units);
        MarkUpdated();

        RaiseDomainEvent(new StockReleasedDomainEvent(Id, orderId, units, AvailableUnits.Value));
    }

    private void MarkUpdated() => LastUpdatedAt = DateTimeOffset.UtcNow;
}
