namespace ShopDemo.Analytics.Api.Services;

/// <summary>
/// Almacén en memoria de los últimos eventos observados (ring buffer).
/// </summary>
public sealed class InMemoryEventStore
{
    private readonly object _lock = new();
    private readonly Queue<StoredEvent> _events = new();
    private const int MaxEvents = 100;

    public void Add(StoredEvent storedEvent)
    {
        lock (_lock)
        {
            _events.Enqueue(storedEvent);
            while (_events.Count > MaxEvents)
                _events.Dequeue();
        }
    }

    public IReadOnlyList<StoredEvent> GetLatest(int take = 50)
    {
        lock (_lock)
        {
            return _events.Reverse().Take(take).ToList();
        }
    }

    public int Count
    {
        get
        {
            lock (_lock)
                return _events.Count;
        }
    }
}

public sealed record StoredEvent(
    string EventType,
    Guid EventId,
    DateTimeOffset OccurredOn,
    string Source,
    string PayloadJson,
    DateTimeOffset ReceivedAt);
