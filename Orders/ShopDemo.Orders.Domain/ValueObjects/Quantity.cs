using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class Quantity : ValueObject
{
    public int Value { get; }

    private Quantity(int value) => Value = value;

    public static Quantity Of(int value)
    {
        if (value <= 0)
            throw new ArgumentException("Quantity must be greater than zero.");
        return new Quantity(value);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }

    public override string ToString() => Value.ToString();
}
