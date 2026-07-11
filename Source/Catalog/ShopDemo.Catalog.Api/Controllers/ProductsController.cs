using MediatR;
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Catalog.Application.Commands.CreateProduct;
using ShopDemo.Catalog.Application.DTOs;

namespace ShopDemo.Catalog.Api.Controllers;

[ApiController]
[Route("api/products")]
public sealed class ProductsController(IMediator mediator) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ProductDto>> Create(
        [FromBody] CreateProductCommand command,
        CancellationToken cancellationToken)
    {
        var product = await mediator.Send(command, cancellationToken);
        return CreatedAtAction(nameof(Create), new { id = product.Id }, product);
    }
}
