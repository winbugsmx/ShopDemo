FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["Source/Orders/ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj", "Source/Orders/ShopDemo.Orders.Api/"]
COPY ["Source/Orders/ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj", "Source/Orders/ShopDemo.Orders.Application/"]
COPY ["Source/Orders/ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj", "Source/Orders/ShopDemo.Orders.Infraestructure/"]
COPY ["Source/Orders/ShopDemo.Orders.Domain/ShopDemo.Orders.Domain.csproj", "Source/Orders/ShopDemo.Orders.Domain/"]
COPY ["Source/ShopDemo.Shared/ShopDemo.Shared.csproj", "Source/ShopDemo.Shared/"]

RUN dotnet restore "Source/Orders/ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj"

COPY . .
WORKDIR "/src/Orders/ShopDemo.Orders.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Orders.Api.dll"]
