using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Domain.ValueObjects;

public sealed class ProductReference : ValueObject
{
    public Guid ProductId { get; }
    public string ProductName { get; }

    private ProductReference(Guid productId, string productName)
    {
        ProductId = productId;
        ProductName = productName;
    }

    public static ProductReference Create(Guid productId, string productName)
    {
        if (productId == Guid.Empty)
            throw new ArgumentException("ProductId cannot be empty.");
        if (string.IsNullOrWhiteSpace(productName))
            throw new ArgumentException("ProductName is required.");

        return new ProductReference(productId, productName.Trim());
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return ProductId;
        yield return ProductName.ToLowerInvariant();
    }
}
