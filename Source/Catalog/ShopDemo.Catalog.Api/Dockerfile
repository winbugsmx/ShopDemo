FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["Source/Catalog/ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj", "Source/Catalog/ShopDemo.Catalog.Api/"]
COPY ["Source/Catalog/ShopDemo.Catalog.Application/ShopDemo.Catalog.Application.csproj", "Source/Catalog/ShopDemo.Catalog.Application/"]
COPY ["Source/Catalog/ShopDemo.Catalog.Infraestructure/ShopDemo.Catalog.Infraestructure.csproj", "Source/Catalog/ShopDemo.Catalog.Infraestructure/"]
COPY ["Source/Catalog/ShopDemo.Catalog.Domain/ShopDemo.Catalog.Domain.csproj", "Source/Catalog/ShopDemo.Catalog.Domain/"]
COPY ["Source/ShopDemo.Shared/ShopDemo.Shared.csproj", "Source/ShopDemo.Shared/"]

RUN dotnet restore "Source/Catalog/ShopDemo.Catalog.Api/ShopDemo.Catalog.Api.csproj"

COPY . .
WORKDIR "/src/Catalog/ShopDemo.Catalog.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Catalog.Api.dll"]
