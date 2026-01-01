# Copilot Instructions for Kali MCP Gemini Server

## Project Overview
This is a .NET 9.0 Model Context Protocol (MCP) server that provides AI agents with secure access to a persistent Kali Linux environment via Docker-in-Docker (DinD). The server exposes Kali Linux tools through MCP protocol for security testing and penetration testing workflows.

## Architecture

### Three-Layer System
1. **MCP Server** (`KaliMCPGemini/`): .NET host running MCP protocol over stdio
2. **Docker-in-Docker Container**: Server runs WITH `--privileged` flag and hosts internal Docker daemon
3. **Persistent Kali Container**: Nested container (`kali-mcp-gemini-persistent`) where commands execute

**Security Model**: The nested architecture isolates the Kali environment from the host Docker daemon. Commands run in the nested Kali container cannot access the host's Docker socket or containers.

### Key Components
- **`KaliMCPGemini/Program.cs`**: MCP server entry point using Microsoft.Extensions.Hosting with stdio transport
- **`KaliMCPGemini/Tools/KaliLinuxToolset.cs`**: Four MCP tools decorated with `[McpServerTool]` attributes
- **`KaliClient/`**: Reference client demonstrating JSON-RPC 2.0 communication over stdio
- **`Dockerfile`**: Multi-stage build installing .NET runtime + Docker Engine (DinD)
- **`entrypoint.sh`**: Starts internal `dockerd` daemon before launching MCP server

## MCP Tool Implementation Pattern

Tools use `[McpServerTool]` attribute from `ModelContextProtocol.Server` package:

```csharp
[McpServerTool(Name = "tool-name"), Description("...")]
public static async Task<string> MethodName(
    [Description("Param description")] string param,
    CancellationToken cancellationToken)
```

**Tool Discovery**: `WithToolsFromAssembly()` in `Program.cs` auto-registers all `[McpServerTool]` methods.

## Available MCP Tools

### `kali-exec` (Primary Tool)
Executes commands in persistent Kali container using `docker exec {container} bash -lc "{command}"`.

**Persistence**: Uses singleton pattern with `SemaphoreSlim` (`_containerSemaphore`) to ensure container lifecycle thread-safety. Container auto-starts if stopped, auto-creates if missing.

**Default Values**:
- Container name: `kali-mcp-gemini-persistent`
- Image: `kalilinux/kali-rolling`

### Container Management Tools
- `kali-container-status`: Queries `docker ps -a --filter name={container}`
- `kali-container-restart`: Stops, removes, and recreates container
- `kali-container-stop`: Stops with optional removal (`removeContainer` parameter)

## Critical Development Workflows

### Building & Running

**Build Docker Image** (required before first use):
```bash
docker build -t kali-mcp-gemini .
docker pull kalilinux/kali-rolling
```

**Run via Gemini CLI**: Auto-discovered from `.gemini/settings.json`

**Run via VS Code**: Configured in `.vscode/mcp.json`

**Local Development** (bypasses Docker for debugging):
```bash
./run_mcp.sh
```
⚠️ Requires Docker daemon accessible on host PATH.

### Testing with KaliClient

Reference client reads `.gemini/settings.json` and communicates via JSON-RPC 2.0:

```bash
# Execute command
dotnet run --project KaliClient -- "nmap -sn 192.168.1.0/24"

# Container status
dotnet run --project KaliClient -- kali-container-status
```

**Protocol Flow**: Initialize → tools/call → Parse response JSON

## Project-Specific Conventions

### Logging
All logs MUST write to stderr (not stdout). Stdout is reserved for MCP protocol JSON messages:
```csharp
builder.Logging.AddConsole(o => o.LogToStandardErrorThreshold = LogLevel.Trace);
```

### Docker Process Management
- Use `ProcessStartInfo` with `RedirectStandardOutput/Error = true`
- Always set `UseShellExecute = false` and `CreateNoWindow = true`
- Use `ArgumentList.Add()` instead of concatenated arguments (prevents injection)
- Encode output with `StandardOutputEncoding = Encoding.UTF8` for special characters

### Container State Management
Three synchronous helpers check state before async operations:
- `IsContainerRunning()`: Checks `docker ps --filter status=running`
- `ContainerExists()`: Checks `docker ps -a`
- `EnsureContainerRunningAsync()`: Idempotent start-or-create with semaphore lock

### Error Handling
Tool methods throw `InvalidOperationException` with Docker error output. MCP framework serializes exceptions to JSON-RPC error responses.

## Key Dependencies

- **`ModelContextProtocol` v0.3.0-preview.4**: Core MCP server framework
- **`Microsoft.Extensions.Hosting` v10.0.1**: Generic host for dependency injection
- **.NET 9.0**: Required runtime (uses `net9.0` target framework)

## Configuration Files

**`.gemini/settings.json`** (Gemini CLI):
```json
{
  "mcpServers": {
    "kali-mcp-gemini": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "--privileged", "kali-mcp-gemini"],
      "trust": true
    }
  }
}
```

**`.vscode/mcp.json`** (VS Code):
- Nearly identical, uses `"type": "stdio"` instead of `"trust": true`

Both MUST include `--privileged` flag for DinD to function.

## Adding New MCP Tools

1. Add static method to `KaliLinuxToolset` class
2. Decorate with `[McpServerTool(Name = "..."), Description("...")]`
3. Use `[Description("...")]` on each parameter
4. Return `Task<string>` (text response) or `Task<object>` (structured data)
5. Accept `CancellationToken cancellationToken` as last parameter
6. Rebuild Docker image: `docker build -t kali-mcp-gemini .`

**No registration code needed** - `WithToolsFromAssembly()` handles discovery.

## Security Considerations

⚠️ **Privileged Container**: Server MUST run with `--privileged` to support DinD. Never expose MCP server to untrusted networks.

**Isolation Benefits**:
- Kali commands cannot access host Docker daemon (nested isolation)
- Compromised Kali container stays within nested boundary
- Host filesystem not mounted into containers

**Monitor Commands**: All `kali-exec` calls are logged. Review for malicious activity.
