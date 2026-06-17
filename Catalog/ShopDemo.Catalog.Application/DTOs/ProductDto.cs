namespace ShopDemo.Catalog.Application.DTOs;

public sealed record ProductDto(
    Guid Id,
    string Name,
    string Description,
    decimal Price,
    string Currency,
    int StockUnits,
    string Category,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastUpdatedAt
)
{
    // Mapeo desde Aggregate — centralizado aquí, no en el Aggregate
    public static ProductDto FromAggregate(Domain.Aggregates.Product product) => new(
        product.Id,
        product.Name.Value,
        product.Description,
        product.Price.Amount,
        product.Price.Currency,
        product.Stock.Units,
        product.Category.Value,
        product.IsActive,
        product.CreatedAt,
        product.LastUpdatedAt);
}
