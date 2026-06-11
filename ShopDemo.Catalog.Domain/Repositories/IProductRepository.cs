using ShopDemo.Catalog.Domain.Aggregates;
using ShopDemo.Catalog.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Domain.Repositories;

/// <summary>
/// Contrato del repositorio definido en el Dominio.
/// La implementación concreta (EF Core) vive en Infrastructure.
/// </summary>
public interface IProductRepository : IRepository<Product, Guid>
{
    Task<IReadOnlyList<Product>> GetByCategoryAsync(
        Category category, CancellationToken ct = default);

    Task<IReadOnlyList<Product>> GetActiveProductsAsync(
        int skip, int take, CancellationToken ct = default);

    Task<int> CountActiveAsync(CancellationToken ct = default);

    Task<bool> ExistsByNameAsync(ProductName name, CancellationToken ct = default);
}