# Backend Dockerfile  
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
USER app
EXPOSE 8080
EXPOSE 8081
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy solution and project files
COPY ["apps/backend/Server.sln", "apps/backend/"]
COPY ["apps/backend/src/Server.WebAPI/Server.WebAPI.csproj", "apps/backend/src/Server.WebAPI/"]
COPY ["apps/backend/src/Server.Application/Server.Application.csproj", "apps/backend/src/Server.Application/"]
COPY ["apps/backend/src/Server.Domain/Server.Domain.csproj", "apps/backend/src/Server.Domain/"]
COPY ["apps/backend/src/Server.Infrastructure/Server.Infrastructure.csproj", "apps/backend/src/Server.Infrastructure/"]

# Restore dependencies
RUN dotnet restore "apps/backend/Server.sln"

# Copy all source files
COPY apps/backend/ apps/backend/
WORKDIR "/src/apps/backend"

# Build the application
RUN dotnet build "Server.sln" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "src/Server.WebAPI/Server.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "Server.WebAPI.dll"]
