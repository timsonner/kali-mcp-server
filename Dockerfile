# Use the .NET SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy the project file and restore dependencies
COPY ["KaliMCPGemini/KaliMCPGemini.csproj", "KaliMCPGemini/"]
RUN dotnet restore "KaliMCPGemini/KaliMCPGemini.csproj"

# Copy the rest of the source code
COPY . .
WORKDIR "/src/KaliMCPGemini"
RUN dotnet build "KaliMCPGemini.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "KaliMCPGemini.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final stage: Create the runtime image
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS final
WORKDIR /app

# Install Docker CLI so the MCP server can interact with the host Docker daemon
ARG DOCKER_CLI_VERSION=27.1.1
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" -o docker.tgz \
    && tar -xzf docker.tgz --strip-components=1 -C /usr/local/bin docker/docker \
    && rm -rf docker docker.tgz

# Copy the published application
COPY --from=publish /app/publish .

# Set the entry point
ENTRYPOINT ["dotnet", "KaliMCPGemini.dll"]
