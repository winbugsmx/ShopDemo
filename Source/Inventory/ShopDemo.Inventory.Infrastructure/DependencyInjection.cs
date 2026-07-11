using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Inventory.Application.Ports.Inbound;
using ShopDemo.Inventory.Application.Ports.Outbound;
using ShopDemo.Inventory.Application.UseCases;
using ShopDemo.Inventory.Infrastructure.Adapters.Messaging;
using ShopDemo.Inventory.Infrastructure.Adapters.Persistence;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Inventory.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInventoryInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<InventoryDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IStockEntryRepository, StockEntryRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        if (configuration.GetValue<bool>("EventHubs:Enabled"))
        {
            services.AddSingleton<IIntegrationEventPublisher, EventHubsIntegrationEventPublisher>();
            services.AddHostedService<CatalogEventsProcessor>();
        }
        else
        {
            services.AddScoped<IIntegrationEventPublisher, LoggingIntegrationEventPublisher>();
        }

        // Use Cases como implementaciones de Inbound Ports (hexagonal)
        services.AddScoped<IRegisterStockUseCase, RegisterStockUseCase>();
        services.AddScoped<IGetStockByProductUseCase, GetStockByProductUseCase>();
        services.AddScoped<IReserveStockUseCase, ReserveStockUseCase>();
        services.AddScoped<IReleaseStockUseCase, ReleaseStockUseCase>();

        return services;
    }
}
