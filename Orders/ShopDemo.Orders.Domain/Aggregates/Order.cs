using ShopDemo.Orders.Domain.Entities;
using ShopDemo.Orders.Domain.Events;
using ShopDemo.Orders.Domain.Exceptions;
using ShopDemo.Orders.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.Aggregates;

public sealed class Order : AggregateRoot<Guid>
{
    private readonly List<OrderLine> _lines = [];

    public CustomerId CustomerId { get; private set; } = null!;
    public ShippingAddress ShippingAddress { get; private set; } = null!;
    public OrderStatus Status { get; private set; } = null!;
    public Money TotalAmount { get; private set; } = null!;
    public IReadOnlyCollection<OrderLine> Lines => _lines.AsReadOnly();
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset? LastUpdatedAt { get; private set; }

    private Order() { }

    public static Order Place(
        CustomerId customerId,
        ShippingAddress shippingAddress,
        IEnumerable<(Guid ProductId, string ProductName, Money UnitPrice, Quantity Quantity)> lines)
    {
        var lineList = lines.ToList();

        if (lineList.Count == 0)
            throw new OrderDomainException("An order must have at least one line.");

        var currency = lineList[0].UnitPrice.Currency;
        if (lineList.Any(l => l.UnitPrice.Currency != currency))
            throw new OrderDomainException("All order lines must use the same currency.");

        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            ShippingAddress = shippingAddress,
            Status = OrderStatus.Pending,
            TotalAmount = Money.Zero(currency),
            CreatedAt = DateTimeOffset.UtcNow
        };

        foreach (var line in lineList)
        {
            var orderLine = OrderLine.Create(
                line.ProductId, line.ProductName, line.UnitPrice, line.Quantity);
            order._lines.Add(orderLine);
            order.TotalAmount = order.TotalAmount.Add(orderLine.LineTotal);
        }

        order.RaiseDomainEvent(new OrderPlacedDomainEvent(
            order.Id,
            order.CustomerId.Value,
            order.TotalAmount.Amount,
            order.TotalAmount.Currency,
            order.Lines.Count));

        return order;
    }

    public void Confirm()
    {
        GuardNotCancelled();

        if (!Status.IsPending)
            throw new OrderDomainException(
                $"Order can only be confirmed from Pending status. Current: {Status}.");

        Status = OrderStatus.Confirmed;
        MarkUpdated();

        RaiseDomainEvent(new OrderConfirmedDomainEvent(
            Id, CustomerId.Value, TotalAmount.Amount, TotalAmount.Currency));
    }

    public void Cancel(string reason)
    {
        GuardNotCancelled();

        if (Status.IsDelivered)
            throw new OrderDomainException("A delivered order cannot be cancelled.");
        if (Status.IsShipped)
            throw new OrderDomainException("A shipped order cannot be cancelled.");
        if (string.IsNullOrWhiteSpace(reason))
            throw new OrderDomainException("Cancellation reason is required.");

        Status = OrderStatus.Cancelled;
        MarkUpdated();

        RaiseDomainEvent(new OrderCancelledDomainEvent(Id, CustomerId.Value, reason.Trim()));
    }

    public void MarkAsShipped()
    {
        GuardNotCancelled();

        if (!Status.IsConfirmed)
            throw new OrderDomainException(
                $"Order can only be shipped from Confirmed status. Current: {Status}.");

        Status = OrderStatus.Shipped;
        MarkUpdated();

        RaiseDomainEvent(new OrderShippedDomainEvent(Id, CustomerId.Value));
    }

    private void GuardNotCancelled()
    {
        if (Status.IsCancelled)
            throw new OrderDomainException("A cancelled order cannot be modified.");
    }

    private void MarkUpdated() => LastUpdatedAt = DateTimeOffset.UtcNow;
}
