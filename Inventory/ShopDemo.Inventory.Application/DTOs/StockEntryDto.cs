namespace ShopDemo.Inventory.Application.DTOs;

public sealed record StockEntryDto(
    Guid ProductId,
    string ProductName,
    int AvailableUnits,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastUpdatedAt)
{
    public static StockEntryDto FromAggregate(Domain.Aggregates.StockEntry entry) => new(
        entry.Id,
        entry.ProductName,
        entry.AvailableUnits.Value,
        entry.CreatedAt,
        entry.LastUpdatedAt);
}
