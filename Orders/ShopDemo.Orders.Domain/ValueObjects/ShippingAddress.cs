using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Domain.ValueObjects;

public sealed class ShippingAddress : ValueObject
{
    public string Street { get; }
    public string City { get; }
    public string PostalCode { get; }
    public string Country { get; }

    private ShippingAddress(string street, string city, string postalCode, string country)
    {
        Street = street;
        City = city;
        PostalCode = postalCode;
        Country = country;
    }

    public static ShippingAddress Create(
        string street, string city, string postalCode, string country)
    {
        if (string.IsNullOrWhiteSpace(street))
            throw new ArgumentException("Street is required.");
        if (string.IsNullOrWhiteSpace(city))
            throw new ArgumentException("City is required.");
        if (string.IsNullOrWhiteSpace(postalCode))
            throw new ArgumentException("Postal code is required.");
        if (string.IsNullOrWhiteSpace(country))
            throw new ArgumentException("Country is required.");

        return new ShippingAddress(
            street.Trim(), city.Trim(), postalCode.Trim(), country.Trim().ToUpperInvariant());
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Street.ToLowerInvariant();
        yield return City.ToLowerInvariant();
        yield return PostalCode.ToLowerInvariant();
        yield return Country.ToLowerInvariant();
    }
}
