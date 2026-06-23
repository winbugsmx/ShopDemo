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
