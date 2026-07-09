FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["AI/ShopDemo.Mcp.Api/ShopDemo.Mcp.Api.csproj", "AI/ShopDemo.Mcp.Api/"]
RUN dotnet restore "AI/ShopDemo.Mcp.Api/ShopDemo.Mcp.Api.csproj"

COPY AI/ShopDemo.Mcp.Api/ AI/ShopDemo.Mcp.Api/
WORKDIR /src/AI/ShopDemo.Mcp.Api
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Mcp.Api.dll"]
