FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
RUN mkdir -p /app/wwwroot/uploads/products

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["ShopNShop.Api.csproj", "."]
RUN dotnet restore "ShopNShop.Api.csproj"
COPY . .
RUN dotnet build "ShopNShop.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ShopNShop.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ShopNShop.Api.dll"]
