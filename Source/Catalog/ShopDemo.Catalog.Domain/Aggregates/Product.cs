using ShopDemo.Catalog.Domain.Events;
using ShopDemo.Catalog.Domain.Exceptions;
using ShopDemo.Catalog.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Aggregates;

/// <summary>
/// Product Aggregate — núcleo del Bounded Context Catalog.
/// Toda la lógica de negocio relacionada con productos vive aquí.
/// </summary>
public sealed class Product : AggregateRoot<Guid>
{
    public ProductName Name { get; private set; } = null!;
    public string Description { get; private set; } = string.Empty;
    public Money Price { get; private set; } = null!;
    public StockLevel Stock { get; private set; } = null!;
    public Category Category { get; private set; } = null!;
    public bool IsActive { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset? LastUpdatedAt { get; private set; }

    // Constructor privado — EF Core lo necesita para rehidratar
    private Product() { }

    // ── Factory Method — única forma de crear un Product ──────────────────

    public static Product Create(
        ProductName name,
        string description,
        Money price,
        StockLevel stock,
        Category category)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = name,
            Description = description,
            Price = price,
            Stock = stock,
            Category = category,
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow
        };

        // Levantar Domain Event — otros contextos pueden reaccionar
        product.RaiseDomainEvent(new ProductCreatedDomainEvent(
            product.Id,
            product.Name.Value,
            product.Price.Amount,
            product.Price.Currency,
            product.Stock.Units,
            product.Category.Value));

        return product;
    }

    // ── Comportamientos del Aggregate ─────────────────────────────────────

    public void UpdateDetails(ProductName? name, string? description)
    {
        GuardIsActive();

        bool changed = false;

        if (name is not null && name != Name)
        {
            Name = name;
            changed = true;
        }

        if (description is not null && description != Description)
        {
            Description = description;
            changed = true;
        }

        if (changed) MarkUpdated();
    }

    public void ChangePrice(Money newPrice)
    {
        GuardIsActive();

        if (newPrice == Price) return;

        var previousPrice = Price;
        Price = newPrice;
        MarkUpdated();

        RaiseDomainEvent(new ProductPriceChangedDomainEvent(
            Id, previousPrice.Amount, newPrice.Amount, newPrice.Currency));
    }

    public void ReplenishStock(int units)
    {
        GuardIsActive();

        if (units <= 0)
            throw new ProductDomainException("Units to replenish must be greater than zero.");

        Stock = Stock.Increase(units);
        MarkUpdated();

        RaiseDomainEvent(new StockReplenishedDomainEvent(Id, units, Stock.Units));
    }

    public void DeductStock(int units)
    {
        GuardIsActive();

        // Toda la validación de negocio está en el Value Object
        Stock = Stock.Decrease(units);
        MarkUpdated();

        if (Stock.Units == 0)
            RaiseDomainEvent(new StockDepletedDomainEvent(Id, Name.Value));
    }

    public void Deactivate()
    {
        if (!IsActive) return;
        IsActive = false;
        MarkUpdated();
        RaiseDomainEvent(new ProductDeactivatedDomainEvent(Id, Name.Value));
    }

    public bool HasSufficientStock(int quantity) => Stock.IsAvailableFor(quantity);

    // ── Guards ────────────────────────────────────────────────────────────

    private void GuardIsActive()
    {
        if (!IsActive)
            throw new ProductDomainException($"Product '{Name}' is deactivated and cannot be modified.");
    }

    private void MarkUpdated() => LastUpdatedAt = DateTimeOffset.UtcNow;
}
