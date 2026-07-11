using MediatR;
using ShopDemo.Catalog.Application.DTOs;
using ShopDemo.Catalog.Application.Ports;
using ShopDemo.Catalog.Domain.Aggregates;
using ShopDemo.Catalog.Domain.Repositories;
using ShopDemo.Catalog.Domain.ValueObjects;
using ShopDemo.Shared.Domain;

namespace ShopDemo.Catalog.Application.Commands.CreateProduct;

/// <summary>
/// Handler del comando CreateProduct.
/// Orquesta: validación → creación del Aggregate → persistencia → publicación de eventos.
/// NO contiene lógica de negocio — esa está en el Aggregate.
/// </summary>
public sealed class CreateProductHandler(
    IProductRepository productRepository,
    IUnitOfWork unitOfWork,
    IDomainEventPublisher eventPublisher
) : IRequestHandler<CreateProductCommand, ProductDto>
{
    public async Task<ProductDto> Handle(
        CreateProductCommand command, CancellationToken ct)
    {
        // 1. Construir Value Objects — el dominio valida las reglas de negocio
        var name = ProductName.Create(command.Name);
        var price = Money.Of(command.Price, command.Currency);
        var stock = StockLevel.Of(command.Stock);
        var category = Category.Of(command.Category);

        // 2. Verificar duplicados — regla de negocio
        if (await productRepository.ExistsByNameAsync(name, ct))
            throw new InvalidOperationException(
                $"A product with name '{name}' already exists.");

        // 3. Crear el Aggregate — lógica en el dominio
        var product = Product.Create(name, command.Description, price, stock, category);

        // 4. Persistir
        await productRepository.AddAsync(product, ct);
        await unitOfWork.SaveChangesAsync(ct);

        // 5. Publicar Domain Events a la infraestructura de mensajería
        await eventPublisher.PublishAsync(product.DomainEvents, ct);
        product.ClearDomainEvents();

        // 6. Retornar DTO (nunca exponer el Aggregate hacia afuera)
        return ProductDto.FromAggregate(product);
    }
}
