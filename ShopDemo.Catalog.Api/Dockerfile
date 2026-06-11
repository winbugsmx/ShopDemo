FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj", "ShopDemo.Catalog.Api/"]
COPY ["ShopDemo.Catalog.Application/ShopDemo.Catalog.Application.csproj", "ShopDemo.Catalog.Application/"]
COPY ["ShopDemo.Catalog.Infraestructure/ShopDemo.Catalog.Infraestructure.csproj", "ShopDemo.Catalog.Infraestructure/"]
COPY ["ShopDemo.Catalog.Domain/ShopDemo.Catalog.Domain.csproj", "ShopDemo.Catalog.Domain/"]
COPY ["ShopDemo.Shared/ShopDemo.Shared.csproj", "ShopDemo.Shared/"]

RUN dotnet restore "ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj"

COPY . .
WORKDIR "/src/ShopDemo.Catalog.Api"
RUN dotnet build -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Catalog.Api.dll"]
