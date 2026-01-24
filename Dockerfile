# Fase 2: Infraestructura de Contenedores
# SDK .NET + PowerShell Core para ejecución desde /src montado
FROM mcr.microsoft.com/dotnet/sdk:8.0

WORKDIR /src

# curl (healthcheck) + PowerShell Core
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl wget apt-transport-https software-properties-common && \
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f packages-microsoft-prod.deb

EXPOSE 5000

# Código montado en /src, almacén en /storage vía docker-compose
CMD ["dotnet", "run", "--project", "/src/Tormentosa.Api.csproj", "--urls", "http://+:5000"]
