using Microsoft.AspNetCore.Mvc;
using ShopDemo.Analytics.Api.Services;

namespace ShopDemo.Analytics.Api.Controllers;

[ApiController]
[Route("api/analytics")]
public sealed class AnalyticsController(InMemoryEventStore eventStore) : ControllerBase
{
    [HttpGet("events")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetEvents([FromQuery] int take = 50)
    {
        var events = eventStore.GetLatest(Math.Clamp(take, 1, 100));
        return Ok(new
        {
            totalBuffered = eventStore.Count,
            returned = events.Count,
            events
        });
    }

    [HttpGet("health")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetHealth() => Ok(new
    {
        service = "ShopDemo.Analytics.Api",
        status = "running",
        bufferedEvents = eventStore.Count
    });
}
