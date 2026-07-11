namespace ShopDemo.Shared.Domain;

public interface IUnitOfWork{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}