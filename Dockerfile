FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["GesFer.Company.csproj", "./"]
RUN dotnet restore "GesFer.Company.csproj"
COPY . .
RUN dotnet build "GesFer.Company.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GesFer.Company.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GesFer.Company.dll"]
