namespace ShopDemo.Inventory.Application.Ports.Inbound;

/// <summary>
/// Puerto de entrada: reservar stock al confirmar un pedido (invocado por Orders).
/// </summary>
public interface IReserveStockUseCase
{
    Task ExecuteAsync(ReserveStockRequest request, CancellationToken ct = default);
}

public sealed record ReserveStockRequest(
    Guid OrderId,
    IReadOnlyList<ReserveStockLineRequest> Lines);

public sealed record ReserveStockLineRequest(Guid ProductId, int Quantity);
