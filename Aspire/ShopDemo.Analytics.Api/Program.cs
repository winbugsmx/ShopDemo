using Microsoft.OpenApi;
using ShopDemo.Analytics.Api.Messaging;
using ShopDemo.Analytics.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ShopDemo Analytics API",
        Version = "v1",
        Description = "Observador de eventos del bus — orquestado por .NET Aspire"
    });
});

builder.Services.AddSingleton<InMemoryEventStore>();
builder.Services.AddHostedService<EventHubAnalyticsProcessor>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(o =>
    {
        o.SwaggerEndpoint("/swagger/v1/swagger.json", "ShopDemo Analytics API v1");
        o.RoutePrefix = "swagger";
    });
}

app.MapDefaultEndpoints();
app.MapControllers();

app.Run();
