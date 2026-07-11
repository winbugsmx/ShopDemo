# Anexo — Código completo MCP Gateway (copiar/integrar)

> Copia cada bloque en `Source/AI/ShopDemo.Mcp.Api/`. Requiere Catalog, Inventory y Analytics en ejecución.

**Guía de desarrollo:** [GUIA-DESARROLLO-INTEGRACIONES.md](../GUIA-DESARROLLO-INTEGRACIONES.md) (etapa 14)  
**Implementación paso a paso:** [IMPLEMENTACION-MCP-GATEWAY.md](./IMPLEMENTACION-MCP-GATEWAY.md)

---
## `Source/AI/ShopDemo.Mcp.Api/Program.cs`

```csharp
using ModelContextProtocol.AspNetCore;
using ShopDemo.Mcp.Api.Tools;

var builder = WebApplication.CreateBuilder(args);

var catalogBase = builder.Configuration["ShopDemo:CatalogApiBaseUrl"] ?? "http://localhost:8001";
var inventoryBase = builder.Configuration["ShopDemo:InventoryApiBaseUrl"] ?? "http://localhost:8003";
var analyticsBase = builder.Configuration["ShopDemo:AnalyticsApiBaseUrl"] ?? "http://localhost:8004";

builder.Services.AddHttpClient("catalog", c => c.BaseAddress = new Uri(catalogBase.TrimEnd('/') + "/"));
builder.Services.AddHttpClient("inventory", c => c.BaseAddress = new Uri(inventoryBase.TrimEnd('/') + "/"));
builder.Services.AddHttpClient("analytics", c => c.BaseAddress = new Uri(analyticsBase.TrimEnd('/') + "/"));

builder.Services.AddHealthChecks();

builder.Services
    .AddMcpServer(options =>
    {
        options.ServerInfo = new()
        {
            Name = "ShopDemo MCP Gateway",
            Version = "1.0.0",
            Description = "Expone operaciones de Catalog, Inventory y Analytics para agentes IA."
        };
    })
    .WithHttpTransport(options => options.Stateless = true)
    .WithTools<ShopDemoMcpTools>();

var app = builder.Build();

app.MapHealthChecks("/health");
app.MapMcp("/mcp");

app.Run();
``` 

---
## `Source/AI/ShopDemo.Mcp.Api/Tools/ShopDemoMcpTools.cs`

```csharp
using System.ComponentModel;
using System.Net.Http.Json;
using System.Text.Json;
using ModelContextProtocol.Server;

namespace ShopDemo.Mcp.Api.Tools;

/// <summary>
/// Herramientas MCP que delegan en las APIs HTTP de ShopDemo.
/// Consumibles por agentes IA (Cursor, Claude Desktop, etc.) vÃ­a transporte HTTP.
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

    [McpServerTool, Description("Lista eventos de integraciÃ³n observados por Analytics (requiere Event Hubs activo).")]
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
``` 

---
## `Source/AI/ShopDemo.Mcp.Api/ShopDemo.Mcp.Api.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="10.0.0" />
    <PackageReference Include="ModelContextProtocol.AspNetCore" Version="1.4.0" />
  </ItemGroup>

</Project>
``` 

