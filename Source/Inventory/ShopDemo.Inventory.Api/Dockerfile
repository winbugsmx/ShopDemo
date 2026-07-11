FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["Source/Inventory/ShopDemo.Inventory.Api/ShopDemo.Inventory.Api.csproj", "Source/Inventory/ShopDemo.Inventory.Api/"]
COPY ["Source/Inventory/ShopDemo.Inventory.Application/ShopDemo.Inventory.Application.csproj", "Source/Inventory/ShopDemo.Inventory.Application/"]
COPY ["Source/Inventory/ShopDemo.Inventory.Infrastructure/ShopDemo.Inventory.Infrastructure.csproj", "Source/Inventory/ShopDemo.Inventory.Infrastructure/"]
COPY ["Source/Inventory/ShopDemo.Inventory.Domain/ShopDemo.Inventory.Domain.csproj", "Source/Inventory/ShopDemo.Inventory.Domain/"]
COPY ["Source/ShopDemo.Shared/ShopDemo.Shared.csproj", "Source/ShopDemo.Shared/"]

RUN dotnet restore "Source/Inventory/ShopDemo.Inventory.Api/ShopDemo.Inventory.Api.csproj"

COPY . .
WORKDIR "/src/Inventory/ShopDemo.Inventory.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Inventory.Api.dll"]
