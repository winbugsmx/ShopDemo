using System;
using System.Collections.Generic;
using System.Text;

namespace ShopDemo.Shared.Domain;

/// <summary>
/// Base para Value Objects. Igualdad por valor de sus componentes.
/// </summary>
public abstract class ValueObject
{
    protected abstract IEnumerable<object?> GetEqualityComponents();

    public override bool Equals(object? obj)
    {
        if (obj is null || obj.GetType() != GetType()) return false;
        return GetEqualityComponents()
            .SequenceEqual(((ValueObject)obj).GetEqualityComponents());
    }

    public override int GetHashCode()
        => GetEqualityComponents()
            .Aggregate(0, (hash, comp) => HashCode.Combine(hash, comp));

    public static bool operator ==(ValueObject? left, ValueObject? right)
        => left?.Equals(right) ?? right is null;
    public static bool operator !=(ValueObject? left, ValueObject? right)
        => !(left == right);
}
