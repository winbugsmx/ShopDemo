using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Catalog.Domain.Repositories;
using ShopDemo.Catalog.Infraestructure.Messaging;
using ShopDemo.Catalog.Infraestructure.Persistence;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Infraestructure;

public static class DependencyInjection
{
    public static IServiceCollection AddCatalogInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<CatalogDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IDomainEventPublisher, LoggingDomainEventPublisher>();

        return services;
    }
}
