using Aspire.Hosting.Azure;

var builder = DistributedApplication.CreateBuilder(args);

// ── Configuración Event Hubs (desde appsettings / user secrets del AppHost) ──
var eventHubsSection = builder.Configuration.GetSection("ShopDemo:EventHubs");
var eventHubsEnabled = eventHubsSection["Enabled"] ?? "true";
var eventHubsConnection = eventHubsSection["ConnectionString"]
    ?? throw new InvalidOperationException(
        "Configure ShopDemo:EventHubs:ConnectionString in AppHost appsettings or user secrets.");
var eventHubName = eventHubsSection["EventHubName"] ?? "shopdemo-events";

// ── PostgreSQL (un servidor, tres bases de datos) ──
var postgres = builder.AddPostgres("postgres")
    .WithDataVolume()
    .WithPgAdmin();

var catalogDb = postgres.AddDatabase("ShopDemoCatalog");
var ordersDb = postgres.AddDatabase("ShopDemoOrders");
var inventoryDb = postgres.AddDatabase("ShopDemoInventory");

// ── Azurite vía Aspire (checkpoints Event Hubs para Inventory y Analytics) ──
var storage = builder.AddAzureStorage("storage")
    .RunAsEmulator(emulator => emulator.WithDataVolume());

var blobs = storage.AddBlobs("blobs");

// Connection string del emulador para checkpoints
const string azuriteBlobConnection =
    "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;" +
    "AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;" +
    "BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;";

// ── Microservicios existentes (sin modificar Program.cs) ──
var catalog = builder.AddProject<Projects.ShopDemo_Catalog_Api>("catalog")
    .WithReference(catalogDb)
    .WithHttpEndpoint(port: 8001, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName);

var inventory = builder.AddProject<Projects.ShopDemo_Inventory_Api>("inventory")
    .WithReference(inventoryDb)
    .WithReference(blobs)
    .WithHttpEndpoint(port: 8003, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName)
    .WithEnvironment("EventHubs__ConsumerGroup", "inventory-service")
    .WithEnvironment("EventHubs__CheckpointStorageConnectionString", azuriteBlobConnection)
    .WithEnvironment("EventHubs__CheckpointContainerName", "inventory-checkpoints");

var orders = builder.AddProject<Projects.ShopDemo_Orders_Api>("orders")
    .WithReference(ordersDb)
    .WithReference(inventory)
    .WithHttpEndpoint(port: 8002, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName)
    .WithEnvironment("InventoryApi__BaseUrl", inventory.GetEndpoint("http"));

// ── Nuevo: Analytics (observador del bus) ──
builder.AddProject<Projects.ShopDemo_Analytics_Api>("analytics")
    .WithReference(blobs)
    .WithHttpEndpoint(port: 8004, targetPort: 8080, name: "http")
    .WithEnvironment("EventHubs__Enabled", eventHubsEnabled)
    .WithEnvironment("EventHubs__ConnectionString", eventHubsConnection)
    .WithEnvironment("EventHubs__EventHubName", eventHubName)
    .WithEnvironment("EventHubs__ConsumerGroup", "analytics-service")
    .WithEnvironment("EventHubs__CheckpointStorageConnectionString", azuriteBlobConnection)
    .WithEnvironment("EventHubs__CheckpointContainerName", "analytics-checkpoints")
    .WaitFor(inventory);

builder.Build().Run();
