namespace ShopDemo.Shared.Domain;

/// <summary>
/// Sirve para liberar recursos de la capa de infraestructura despues de persistir en la base de datos.
/// </summary>

public abstract class AggregateRoot<TId> : Entity<TId> where TId : notnull{
    private readonly List<IDomainEvent> _domainEvents = [];

    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    protected AggregateRoot()
    {

    }

    protected AggregateRoot(TId id) : base(id)
    {

    }
    
    protected void RaiseDomainEvent(IDomainEvent domainEvent) => _domainEvents.Add(domainEvent);

    public void ClearDomainEvents() => _domainEvents.Clear();
}