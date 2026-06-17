using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.ValueObjects;

public sealed class Category : ValueObject
{
    // Valores válidos del dominio — no enums para permitir extensión sin recompilación
    public static readonly Category Electronics = new("Electronics");
    public static readonly Category Clothing = new("Clothing");
    public static readonly Category Food = new("Food");
    public static readonly Category Books = new("Books");
    public static readonly Category Sports = new("Sports");

    private static readonly HashSet<string> _validCategories = new(StringComparer.OrdinalIgnoreCase)
        { "Electronics", "Clothing", "Food", "Books", "Sports" };

    public string Value { get; }

    private Category(string value) => Value = value;

    public static Category Of(string value)
    {
        if (!_validCategories.Contains(value))
            throw new ArgumentException(
                $"'{value}' is not a valid category. Valid: {string.Join(", ", _validCategories)}");
        return new Category(value);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToLowerInvariant();
    }

    public override string ToString() => Value;
}

