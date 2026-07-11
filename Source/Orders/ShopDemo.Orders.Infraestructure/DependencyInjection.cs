using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Orders.Application.Ports;
using ShopDemo.Orders.Domain.Repositories;
using ShopDemo.Orders.Infraestructure.Integrations;
using ShopDemo.Orders.Infraestructure.Messaging;
using ShopDemo.Orders.Infraestructure.Persistence;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Orders.Infraestructure;

public static class DependencyInjection
{
    public static IServiceCollection AddOrdersInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<OrdersDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        if (configuration.GetValue<bool>("EventHubs:Enabled"))
            services.AddSingleton<IDomainEventPublisher, EventHubsDomainEventPublisher>();
        else
            services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();

        var inventoryBaseUrl = configuration["InventoryApi:BaseUrl"]
            ?? "http://localhost:8003";

        services.AddHttpClient<IInventoryService, InventoryHttpClient>(client =>
        {
            client.BaseAddress = new Uri(inventoryBaseUrl.TrimEnd('/') + "/");
        });

        return services;
    }
}
