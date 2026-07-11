namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada: liberar stock al cancelar un pedido confirmado.
/// </summary>
public interface IReleaseStockUseCase
{
    Task ExecuteAsync(ReleaseStockRequest request, CancellationToken ct = default);
}

public sealed record ReleaseStockRequest(
    Guid OrderId,
    IReadOnlyList<ReleaseStockLineRequest> Lines);

public sealed record ReleaseStockLineRequest(Guid ProductId, int Quantity);
