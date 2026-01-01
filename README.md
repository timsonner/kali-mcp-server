# Kali MCP Gemini Server

A .NET-based [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that provides a persistent Kali Linux environment for Gemini agents.

## Project Structure

- **`KaliMCPGemini/`**: The core MCP server implementation in C#.
- **`KaliClient/`**: A reference .NET client that acts as a bridge for Gemini agents.
- **`Dockerfile`**: Builds the server image (`kali-mcp-gemini`).
- **`.gemini/settings.json`**: Configuration source for launching the server.

## Architecture: Docker-in-Docker (DinD)

This project uses **Docker-in-Docker (DinD)** for enhanced security and isolation.
The MCP server container runs with the `--privileged` flag and hosts its own internal Docker daemon. This ensures that the Kali Linux environment and any commands executed within it are isolated from the host machine's Docker daemon and file system.

### Key Benefits:
- **Isolation**: Compromise of the Kali container does not provide access to the host Docker daemon.
- **Clean Slate**: Each server instance starts with a fresh Docker environment.

### Requirements:
- The server container **must** be run with the `--privileged` flag to allow the internal Docker daemon to function.

## Available Tools

The server exposes the following MCP tools. Agents should generally access these via the provided `KaliClient`.

### 1. `kali-exec`
Executes a shell command inside the persistent Kali container.
- **Arguments**:
    - `command` (string, required): The bash command to run (e.g., `nmap 192.168.1.1`).
    - `image` (string, optional): Docker image to use (default: `kalilinux/kali-rolling`).
    - `containerName` (string, optional): Container name (default: `kali-mcp-gemini-persistent`).

### 2. `kali-container-status`
Checks the status of the persistent container.
- **Arguments**:
    - `containerName` (string, optional)

### 3. `kali-container-restart`
Restarts the persistent container (useful if a tool hangs or networking breaks).
- **Arguments**:
    - `containerName` (string, optional)
    - `image` (string, optional)

### 4. `kali-container-stop`
Stops (and optionally removes) the container.
- **Arguments**:
    - `containerName` (string, optional)
    - `removeContainer` (boolean, optional): If true, deletes the container (default: `false`).

## Setup

1.  **Prerequisites**:
    -   Docker Desktop (running)
    -   .NET 9.0 SDK

2.  **Build the Server Image**:
    ```bash
    docker build -t kali-mcp-gemini .
    ```

3.  **Pull Kali Image**:
    ```bash
    docker pull kalilinux/kali-rolling
    ```

## Running the Server

### 1. Gemini CLI
The server is automatically discovered by the Gemini CLI using the configuration in `.gemini/settings.json`. Ensure you have built the Docker image first.

### 2. VS Code
To use the server in VS Code:
- Copy or link `.vscode/mcp.json` to your VS Code MCP settings.
- The server will run inside a Docker container.

### 3. Local Development (No Docker)
To run the server directly on your host machine for development or debugging:
```bash
chmod +x run_mcp.sh
./run_mcp.sh
```

## Usage

### Reference Client
The `KaliClient` is a reference implementation that demonstrates how to programmatically interact with the MCP server. It reads the server configuration from `.gemini/settings.json`.

**Run a Bash Command:**
```bash
dotnet run --project KaliClient -- "cat /etc/os-release"
```

**Check Container Status:**
```bash
dotnet run --project KaliClient -- kali-container-status
```

**Restart or Stop:**
```bash
dotnet run --project KaliClient -- kali-container-restart
dotnet run --project KaliClient -- kali-container-stop
```

### Gemini Agent Interaction
When running via the Gemini CLI, the agent can call these tools directly to interact with the Kali environment.

## Security Implications

⚠️ **Privileged Mode Required** ⚠️

To support Docker-in-Docker (DinD), the MCP server container must be run with the `--privileged` flag. This allows the internal Docker daemon to manage containers and networking.

### Isolation and Safety:
1.  **Host Protection**: Unlike standard Docker-based tools that bind to `/var/run/docker.sock`, this server uses an internal Docker daemon. This means the Kali Linux container and its commands **cannot** see or control the host machine's Docker daemon or containers.
2.  **Filesystem Isolation**: The Kali environment operates within its own virtualized filesystem inside the server container, providing a strong layer of isolation from the host OS.
3.  **Restricted Scope**: While the server requires high privileges from the host to run its internal daemon, the *agent's* commands are restricted to the nested Kali environment.

### Best Practices:
- Ensure you trust the MCP server image before running it with `--privileged`.
- Monitor the commands being executed via `kali-exec` to maintain oversight of agent activity.
- Do not expose the MCP server's communication channel to untrusted networks.
