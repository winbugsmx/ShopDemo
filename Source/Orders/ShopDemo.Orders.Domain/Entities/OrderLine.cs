using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Entities;

public sealed class OrderLine : Entity<Guid>
{
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; } = string.Empty;
    public Money UnitPrice { get; private set; } = null!;
    public Quantity Quantity { get; private set; } = null!;
    public Money LineTotal { get; private set; } = null!;

    private OrderLine() { }

    internal static OrderLine Create(
        Guid productId,
        string productName,
        Money unitPrice,
        Quantity quantity)
    {
        if (productId == Guid.Empty)
            throw new ArgumentException("ProductId cannot be empty.");
        if (string.IsNullOrWhiteSpace(productName))
            throw new ArgumentException("ProductName is required.");

        return new OrderLine
        {
            Id = Guid.NewGuid(),
            ProductId = productId,
            ProductName = productName.Trim(),
            UnitPrice = unitPrice,
            Quantity = quantity,
            LineTotal = unitPrice.Multiply(quantity.Value)
        };
    }
}
