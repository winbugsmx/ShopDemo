using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi;
using ShopDemo.Inventory.Api.Middleware;
using ShopDemo.Inventory.Infrastructure;
using ShopDemo.Inventory.Infrastructure.Adapters.Persistence;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ShopDemo Inventory API",
        Version = "v1",
        Description = "Microservicio de inventario — Arquitectura Hexagonal"
    });
});

builder.Services.AddInventoryInfrastructure(builder.Configuration);

var app = builder.Build();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

await DatabaseInitializer.EnsureCreatedAsync(connectionString);

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();
    await db.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(o =>
    {
        o.SwaggerEndpoint("/swagger/v1/swagger.json", "ShopDemo Inventory API v1");
        o.RoutePrefix = "swagger";
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.MapControllers();

app.Run();
