using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class StockLevel : ValueObject
{
    public int Units { get; }

    private StockLevel(int units) => Units = units;

    public static StockLevel Of(int units)
    {
        if (units < 0)
            throw new ArgumentException("Stock level cannot be negative.");
        return new StockLevel(units);
    }

    public static StockLevel Zero => new(0);

    public StockLevel Decrease(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity to decrease must be positive.");
        if (Units < quantity)
            throw new InvalidOperationException(
                $"Insufficient stock. Available: {Units}, requested: {quantity}.");
        return new StockLevel(Units - quantity);
    }

    public StockLevel Increase(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity to increase must be positive.");
        return new StockLevel(Units + quantity);
    }

    public bool IsAvailableFor(int quantity) => Units >= quantity;

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Units;
    }

    public override string ToString() => $"{Units} units";
}
