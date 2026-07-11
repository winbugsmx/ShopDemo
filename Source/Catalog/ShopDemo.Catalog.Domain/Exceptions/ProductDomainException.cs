namespace ShopDemo.Catalog.Domain.Exceptions;

public sealed class ProductDomainException : Exception
{
    public ProductDomainException(string message) : base(message) { }
    public ProductDomainException(string message, Exception inner) : base(message, inner) { }
}
