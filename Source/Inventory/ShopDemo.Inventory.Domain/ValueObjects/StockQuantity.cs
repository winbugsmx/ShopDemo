using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.ValueObjects;

public sealed class StockQuantity : ValueObject
{
    public int Value { get; }

    private StockQuantity(int value) => Value = value;

    public static StockQuantity Of(int value)
    {
        if (value < 0)
            throw new ArgumentException("Stock quantity cannot be negative.");
        return new StockQuantity(value);
    }

    public static StockQuantity Zero => new(0);

    public StockQuantity Decrease(int units)
    {
        if (units <= 0)
            throw new ArgumentException("Units to decrease must be positive.");
        if (Value < units)
            throw new InvalidOperationException(
                $"Insufficient stock. Available: {Value}, requested: {units}.");
        return new StockQuantity(Value - units);
    }

    public StockQuantity Increase(int units)
    {
        if (units <= 0)
            throw new ArgumentException("Units to increase must be positive.");
        return new StockQuantity(Value + units);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }
}
