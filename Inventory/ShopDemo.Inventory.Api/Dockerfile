FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["Inventory/ShopDemo.Inventory.Api/ShopDemo.Inventory.Api.csproj", "Inventory/ShopDemo.Inventory.Api/"]
COPY ["Inventory/ShopDemo.Inventory.Application/ShopDemo.Inventory.Application.csproj", "Inventory/ShopDemo.Inventory.Application/"]
COPY ["Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj", "Inventory/ShopDemo.Inventory.Infrastructure/"]
COPY ["Inventory/ShopDemo.Inventory.Domain/ShopDemo.Inventory.Domain.csproj", "Inventory/ShopDemo.Inventory.Domain/"]
COPY ["ShopDemo.Shared/ShopDemo.Shared.csproj", "ShopDemo.Shared/"]

RUN dotnet restore "Inventory/ShopDemo.Inventory.Api/ShopDemo.Inventory.Api.csproj"

COPY . .
WORKDIR "/src/Inventory/ShopDemo.Inventory.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Inventory.Api.dll"]
