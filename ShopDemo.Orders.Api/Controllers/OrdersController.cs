using MediatR;
using Microsoft.AspNetCore.Mvc;
using ShopDemo.Orders.Application.Commands.CancelOrder;
using ShopDemo.Orders.Application.Commands.ConfirmOrder;
using ShopDemo.Orders.Application.Commands.PlaceOrder;
using ShopDemo.Orders.Application.DTOs;
using ShopDemo.Orders.Application.Queries.GetOrderById;
using ShopDemo.Orders.Application.Queries.GetOrdersByCustomer;

namespace ShopDemo.Orders.Api.Controllers;

[ApiController]
[Route("api/orders")]
public sealed class OrdersController(IMediator mediator) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<OrderDto>> Place(
        [FromBody] PlaceOrderCommand command, CancellationToken ct)
    {
        var order = await mediator.Send(command, ct);
        return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OrderDto>> GetById(Guid id, CancellationToken ct)
    {
        var order = await mediator.Send(new GetOrderByIdQuery(id), ct);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<OrderDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<OrderDto>>> GetByCustomer(
        [FromQuery] Guid customerId, CancellationToken ct)
    {
        var orders = await mediator.Send(new GetOrdersByCustomerQuery(customerId), ct);
        return Ok(orders);
    }

    [HttpPost("{id:guid}/confirm")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> Confirm(Guid id, CancellationToken ct)
    {
        var order = await mediator.Send(new ConfirmOrderCommand(id), ct);
        return Ok(order);
    }

    [HttpPost("{id:guid}/cancel")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> Cancel(
        Guid id, [FromBody] CancelOrderRequest request, CancellationToken ct)
    {
        var order = await mediator.Send(new CancelOrderCommand(id, request.Reason), ct);
        return Ok(order);
    }

    public sealed record CancelOrderRequest(string Reason);
}
