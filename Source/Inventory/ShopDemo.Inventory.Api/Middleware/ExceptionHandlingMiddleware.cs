using System.Text.Json;
using ShopDemo.Inventory.Domain.Exceptions;

namespace ShopDemo.Inventory.Api.Middleware;

public sealed class ExceptionHandlingMiddleware(
    RequestDelegate next,
    ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, title, detail) = exception switch
        {
            InventoryDomainException domain => (
                StatusCodes.Status400BadRequest,
                "Domain rule violation",
                domain.Message),
            InvalidOperationException op => (
                StatusCodes.Status409Conflict,
                "Conflict",
                op.Message),
            KeyNotFoundException notFound => (
                StatusCodes.Status404NotFound,
                "Not found",
                notFound.Message),
            _ => (
                StatusCodes.Status500InternalServerError,
                "Internal server error",
                "An unexpected error occurred.")
        };

        if (statusCode == StatusCodes.Status500InternalServerError)
            logger.LogError(exception, "Unhandled exception");
        else
            logger.LogWarning(exception, "Handled: {Title}", title);

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new
        {
            title,
            status = statusCode,
            detail,
            traceId = context.TraceIdentifier
        }));
    }
}
