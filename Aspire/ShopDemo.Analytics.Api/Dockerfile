FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["Aspire/ShopDemo.Analytics.Api/ShopDemo.Analytics.Api.csproj", "Aspire/ShopDemo.Analytics.Api/"]
COPY ["Aspire/ShopDemo.ServiceDefaults/ShopDemo.ServiceDefaults.csproj", "Aspire/ShopDemo.ServiceDefaults/"]
COPY ["ShopDemo.Shared/ShopDemo.Shared.csproj", "ShopDemo.Shared/"]

RUN dotnet restore "Aspire/ShopDemo.Analytics.Api/ShopDemo.Analytics.Api.csproj"

COPY . .
WORKDIR "/src/Aspire/ShopDemo.Analytics.Api"
RUN dotnet publish -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "ShopDemo.Analytics.Api.dll"]
