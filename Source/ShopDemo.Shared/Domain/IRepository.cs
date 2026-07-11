namespace ShopDemo.Shared.Domain;

public interface IRepository<TAgregate, TId> where TAgregate : AggregateRoot<TId> where TId : notnull{
    Task<TAgregate> GetByIdAsync(TId id, CancellationToken cancellationToken = default);
    Task<IEnumerable<TAgregate>> GetAllAsync(CancellationToken cancellationToken = default);
    Task AddAsync(TAgregate aggregate, CancellationToken cancellationToken = default);
    Task UpdateAsync(TAgregate aggregate, CancellationToken cancellationToken = default);
    Task DeleteAsync(TAgregate aggregate, CancellationToken cancellationToken = default);
}