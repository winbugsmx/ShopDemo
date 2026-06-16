namespace ShopDemo.Orders.Domain.Exceptions;

public sealed class OrderDomainException : Exception
{
    public OrderDomainException(string message) : base(message) { }
    public OrderDomainException(string message, Exception inner) : base(message, inner) { }
}
