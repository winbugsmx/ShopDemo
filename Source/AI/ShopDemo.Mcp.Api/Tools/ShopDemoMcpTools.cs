using System.ComponentModel;
using System.Net.Http.Json;
using System.Text.Json;
using ModelContextProtocol.Server;

namespace ShopDemo.Mcp.Api.Tools;

/// <summary>
/// Herramientas MCP que delegan en las APIs HTTP de ShopDemo.
/// Consumibles por agentes IA (Cursor, Claude Desktop, etc.) vía transporte HTTP.
/// </summary>
[McpServerToolType]
public sealed class ShopDemoMcpTools(IHttpClientFactory httpClientFactory, IConfiguration configuration)
{
    private HttpClient CatalogClient => httpClientFactory.CreateClient("catalog");
    private HttpClient InventoryClient => httpClientFactory.CreateClient("inventory");
    private HttpClient AnalyticsClient => httpClientFactory.CreateClient("analytics");

    [McpServerTool, Description("Crea un producto en Catalog API. Devuelve JSON con el producto creado incluyendo su id.")]
    public async Task<string> CreateProduct(
        string name,
        string description,
        decimal price,
        string currency = "USD",
        int stock = 10,
        string category = "Electronics",
        CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            name,
            description,
            price,
            currency,
            stock,
            category
        };

        var response = await CatalogClient.PostAsJsonAsync("api/products", payload, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        return response.IsSuccessStatusCode
            ? body
            : $"Error {(int)response.StatusCode}: {body}";
    }

    [McpServerTool, Description("Consulta unidades disponibles en Inventory para un productId (GUID).")]
    public async Task<string> GetProductStock(
        Guid productId,
        CancellationToken cancellationToken = default)
    {
        var response = await InventoryClient.GetAsync($"api/inventory/{productId}", cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        return response.IsSuccessStatusCode
            ? body
            : $"Error {(int)response.StatusCode}: {body}";
    }

    [McpServerTool, Description("Lista eventos de integración observados por Analytics (requiere Event Hubs activo).")]
    public async Task<string> ListAnalyticsEvents(
        CancellationToken cancellationToken = default)
    {
        var response = await AnalyticsClient.GetAsync("api/analytics/events", cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        return response.IsSuccessStatusCode
            ? body
            : $"Error {(int)response.StatusCode}: {body}";
    }

    [McpServerTool, Description("Resumen de conectividad con las APIs configuradas en ShopDemo:Mcp.")]
    public async Task<string> GetShopDemoStatus(CancellationToken cancellationToken = default)
    {
        var catalogUrl = configuration["ShopDemo:CatalogApiBaseUrl"] ?? "not-set";
        var inventoryUrl = configuration["ShopDemo:InventoryApiBaseUrl"] ?? "not-set";
        var analyticsUrl = configuration["ShopDemo:AnalyticsApiBaseUrl"] ?? "not-set";

        async Task<string> Ping(HttpClient client, string label)
        {
            try
            {
                var response = await client.GetAsync("health", cancellationToken);
                return $"{label}: {(response.IsSuccessStatusCode ? "OK" : $"HTTP {(int)response.StatusCode}")}";
            }
            catch (Exception ex)
            {
                return $"{label}: UNREACHABLE ({ex.Message})";
            }
        }

        var lines = new[]
        {
            $"Catalog base: {catalogUrl}",
            $"Inventory base: {inventoryUrl}",
            $"Analytics base: {analyticsUrl}",
            await Ping(CatalogClient, "Catalog /health"),
            await Ping(InventoryClient, "Inventory /health"),
            await Ping(AnalyticsClient, "Analytics /health")
        };

        return JsonSerializer.Serialize(lines);
    }
}
