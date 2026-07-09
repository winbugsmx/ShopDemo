using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class ProductName : ValueObject
{
    public string Value { get; }

    private ProductName(string value) => Value = value;

    public static ProductName Create(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Product name cannot be empty.");
        if (value.Length < 3)
            throw new ArgumentException("Product name must be at least 3 characters.");
        if (value.Length > 200)
            throw new ArgumentException("Product name cannot exceed 200 characters.");

        return new ProductName(value.Trim());
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToLowerInvariant();
    }

    public override string ToString() => Value;

    // Conversión implícita para comodidad
    public static implicit operator string(ProductName name) => name.Value;
}
