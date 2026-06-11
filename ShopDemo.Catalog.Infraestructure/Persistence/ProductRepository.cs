using Microsoft.EntityFrameworkCore;
using ShopDemo.Catalog.Domain.Aggregates;
using ShopDemo.Catalog.Domain.Repositories;
using ShopDemo.Catalog.Domain.ValueObjects;

namespace ShopDemo.Catalog.Infraestructure.Persistence;

public sealed class ProductRepository(CatalogDbContext dbContext) : IProductRepository
{
    public async Task<Product> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await dbContext.Products
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        return product ?? throw new KeyNotFoundException($"Product with id '{id}' was not found.");
    }

    public async Task<IEnumerable<Product>> GetAllAsync(CancellationToken cancellationToken = default)
        => await dbContext.Products.AsNoTracking().ToListAsync(cancellationToken);

    public async Task AddAsync(Product aggregate, CancellationToken cancellationToken = default)
        => await dbContext.Products.AddAsync(aggregate, cancellationToken);

    public Task UpdateAsync(Product aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Products.Update(aggregate);
        return Task.CompletedTask;
    }

    public Task DeleteAsync(Product aggregate, CancellationToken cancellationToken = default)
    {
        dbContext.Products.Remove(aggregate);
        return Task.CompletedTask;
    }

    public async Task<IReadOnlyList<Product>> GetByCategoryAsync(
        Category category, CancellationToken ct = default)
        => await dbContext.Products
            .AsNoTracking()
            .Where(p => p.Category.Value == category.Value)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<Product>> GetActiveProductsAsync(
        int skip, int take, CancellationToken ct = default)
        => await dbContext.Products
            .AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.Name.Value)
            .Skip(skip)
            .Take(take)
            .ToListAsync(ct);

    public Task<int> CountActiveAsync(CancellationToken ct = default)
        => dbContext.Products.CountAsync(p => p.IsActive, ct);

    public Task<bool> ExistsByNameAsync(ProductName name, CancellationToken ct = default)
        => dbContext.Products.AnyAsync(
            p => p.Name.Value.ToLower() == name.Value.ToLower(), ct);
}
