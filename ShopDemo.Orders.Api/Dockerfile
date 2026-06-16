FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj", "ShopDemo.Orders.Api/"]
COPY ["ShopDemo.Orders.Application/ShopDemo.Orders.Application.csproj", "ShopDemo.Orders.Application/"]
COPY ["ShopDemo.Orders.Infraestructure/ShopDemo.Orders.Infraestructure.csproj", "ShopDemo.Orders.Infraestructure/"]
COPY ["ShopDemo.Orders.Domain/ShopDemo.Orders.Domain.csproj", "ShopDemo.Orders.Domain/"]
COPY ["ShopDemo.Shared/ShopDemo.Shared.csproj", "ShopDemo.Shared/"]

RUN dotnet restore "ShopDemo.Orders.Api/ShopDemo.Orders.Api.csproj"

COPY . .
WORKDIR "/src/ShopDemo.Orders.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Orders.Api.dll"]
