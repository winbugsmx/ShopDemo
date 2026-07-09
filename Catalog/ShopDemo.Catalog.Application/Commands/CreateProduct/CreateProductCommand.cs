using MediatR;
using ShopDemo.Catalog.Application.DTOs;

namespace ShopDemo.Catalog.Application.Commands.CreateProduct;

/// <summary>
/// Comando para crear un producto. Implementa IRequest de MediatR.
/// Devuelve el DTO del producto creado.
/// </summary>
public sealed record CreateProductCommand(
    string Name,
    string Description,
    decimal Price,
    string Currency,
    int Stock,
    string Category
) : IRequest<ProductDto>;
