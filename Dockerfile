FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000

# Instalar PowerShell Core en la imagen base
RUN apt-get update && \
    apt-get install -y wget apt-transport-https software-properties-common && \
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/* && \
    rm packages-microsoft-prod.deb

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Tormentosa.Api/Tormentosa.Api.csproj", "src/Tormentosa.Api/"]
RUN dotnet restore "src/Tormentosa.Api/Tormentosa.Api.csproj"
COPY . .
RUN dotnet build "src/Tormentosa.Api/Tormentosa.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "src/Tormentosa.Api/Tormentosa.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Crear directorio para storage (se mapeará como volumen)
RUN mkdir -p /app/storage

ENTRYPOINT ["dotnet", "Tormentosa.Api.dll"]
