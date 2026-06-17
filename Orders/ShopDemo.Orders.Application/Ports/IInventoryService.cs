namespace ShopDemo.Orders.Application.Ports;

/// <summary>
/// Puerto de salida hacia el bounded context Inventory.
/// Orders invoca este contrato al confirmar/cancelar pedidos.
/// </summary>
public interface IInventoryService
{
    Task ReserveStockAsync(
        Guid orderId,
        IReadOnlyList<InventoryLineRequest> lines,
        CancellationToken ct = default);

    Task ReleaseStockAsync(
        Guid orderId,
        IReadOnlyList<InventoryLineRequest> lines,
        CancellationToken ct = default);
}

public sealed record InventoryLineRequest(Guid ProductId, int Quantity);
