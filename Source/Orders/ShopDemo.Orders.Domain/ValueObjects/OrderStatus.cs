using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class OrderStatus : ValueObject
{
    public static readonly OrderStatus Pending = new("Pending");
    public static readonly OrderStatus Confirmed = new("Confirmed");
    public static readonly OrderStatus Shipped = new("Shipped");
    public static readonly OrderStatus Delivered = new("Delivered");
    public static readonly OrderStatus Cancelled = new("Cancelled");

    private static readonly HashSet<string> ValidStatuses = new(StringComparer.OrdinalIgnoreCase)
        { "Pending", "Confirmed", "Shipped", "Delivered", "Cancelled" };

    public string Value { get; }

    private OrderStatus(string value) => Value = value;

    public static OrderStatus Of(string value)
    {
        if (!ValidStatuses.Contains(value))
            throw new ArgumentException(
                $"'{value}' is not a valid order status. Valid: {string.Join(", ", ValidStatuses)}");
        return new OrderStatus(value);
    }

    public bool IsPending => Value == Pending.Value;
    public bool IsConfirmed => Value == Confirmed.Value;
    public bool IsShipped => Value == Shipped.Value;
    public bool IsDelivered => Value == Delivered.Value;
    public bool IsCancelled => Value == Cancelled.Value;

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToLowerInvariant();
    }

    public override string ToString() => Value;
}
