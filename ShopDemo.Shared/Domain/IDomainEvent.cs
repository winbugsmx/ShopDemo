namespace ShopDemo.Shared.Domain;

public interface IDomainEvent{
    Guid EventId { get; }
    DateTimeOffset OccurredOn { get; }
}