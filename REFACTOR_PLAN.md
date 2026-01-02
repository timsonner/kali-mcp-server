# Refactor Plan: Remove "Gemini" Naming

**Goal**: Rename project from "Kali MCP Gemini Server" to "Kali MCP Server" to reflect that it's not Gemini-specific.

**Estimated Time**: 15-20 minutes

---

## Pre-Refactor Checklist

- [ ] Commit any pending changes
- [ ] Ensure no active pentest sessions using the container
- [ ] Note any custom tools installed in the container (will be lost if volume is removed)

---

## Phase 1: Rename Project Directory & Files

```bash
# Rename project directory
mv KaliMCPGemini KaliMCP

# Rename .csproj file
mv KaliMCP/KaliMCPGemini.csproj KaliMCP/KaliMCP.csproj
```

- [ ] Rename `KaliMCPGemini/` → `KaliMCP/`
- [ ] Rename `KaliMCPGemini.csproj` → `KaliMCP.csproj`

---

## Phase 2: Update Source Code

### KaliMCP/Program.cs
- [ ] Change namespace `KaliMCPGemini` → `KaliMCP`

### KaliMCP/Tools/KaliLinuxToolset.cs
- [ ] Change namespace `KaliMCPGemini.Tools` → `KaliMCP.Tools`
- [ ] Change `DefaultContainerName` from `kali-mcp-gemini-persistent` → `kali-mcp-persistent`
- [ ] Update all `[Description]` attributes referencing container name

### KaliClient/Program.cs
- [ ] Change container name `kali-mcp-gemini-persistent` → `kali-mcp-persistent` (2 occurrences)
- [ ] Optional: Rename `GEMINI_SETTINGS_PATH` → `MCP_SETTINGS_PATH`

---

## Phase 3: Update Build/Runtime Files

### Dockerfile
- [ ] `COPY ["KaliMCPGemini/KaliMCPGemini.csproj", "KaliMCPGemini/"]` → `COPY ["KaliMCP/KaliMCP.csproj", "KaliMCP/"]`
- [ ] `RUN dotnet restore "KaliMCPGemini/KaliMCPGemini.csproj"` → `RUN dotnet restore "KaliMCP/KaliMCP.csproj"`
- [ ] `WORKDIR "/src/KaliMCPGemini"` → `WORKDIR "/src/KaliMCP"`
- [ ] `RUN dotnet build "KaliMCPGemini.csproj"` → `RUN dotnet build "KaliMCP.csproj"`
- [ ] `RUN dotnet publish "KaliMCPGemini.csproj"` → `RUN dotnet publish "KaliMCP.csproj"`

### entrypoint.sh
- [ ] `dotnet KaliMCPGemini.dll` → `dotnet KaliMCP.dll`

### run_mcp.sh
- [ ] Update project path from `KaliMCPGemini/KaliMCPGemini.csproj` → `KaliMCP/KaliMCP.csproj`

---

## Phase 4: Update Config Files

### .vscode/mcp.json
- [ ] `"kali-mcp-gemini":` → `"kali-mcp":`
- [ ] Image name `"kali-mcp-gemini"` → `"kali-mcp"`

### .copilot/mcp-config.json
- [ ] Image name `"kali-mcp-gemini"` → `"kali-mcp"`

### .gemini/settings.json (keep file, update contents)
- [ ] `"kali-mcp-gemini":` → `"kali-mcp":`
- [ ] Image name `"kali-mcp-gemini"` → `"kali-mcp"`

---

## Phase 5: Update Documentation

### README.md (~50 replacements)
- [ ] Title: "Kali MCP Gemini Server" → "Kali MCP Server"
- [ ] Description: Remove "for Gemini agents" → "for AI agents"
- [ ] Project structure: `KaliMCPGemini/` references
- [ ] All `kali-mcp-gemini` → `kali-mcp` (image name)
- [ ] All `kali-mcp-gemini-persistent` → `kali-mcp-persistent` (container name)
- [ ] Keep `.gemini/` folder references as-is
- [ ] Keep "Gemini CLI" section name (it's the product name)

### .github/copilot-instructions.md (~20 replacements)
- [ ] Title and references to project name
- [ ] `KaliMCPGemini/` → `KaliMCP/`
- [ ] Container/image names

### .gitignore
- [ ] Keep `.gemini/tmp/` as-is (Gemini CLI requirement)

---

## Phase 6: Post-Refactor Cleanup

```bash
# Stop existing containers
docker stop $(docker ps -q --filter ancestor=kali-mcp-gemini) 2>/dev/null

# Remove old containers  
docker rm $(docker ps -aq --filter ancestor=kali-mcp-gemini) 2>/dev/null

# Optional: Remove old volume (WARNING: loses installed tools like nmap, openvpn)
# docker volume rm kali_mcp_data

# Remove old image
docker rmi kali-mcp-gemini

# Build new image
docker build -t kali-mcp .

# Update user config files
cp .copilot/mcp-config.json ~/.copilot/mcp-config.json

# Test the refactor
dotnet run --project KaliClient -- "echo 'Hello from Kali MCP'"
```

- [ ] Stop and remove old containers
- [ ] Decide: Keep or remove `kali_mcp_data` volume
- [ ] Remove old Docker image
- [ ] Build new Docker image as `kali-mcp`
- [ ] Copy updated config to `~/.copilot/`
- [ ] Test with KaliClient
- [ ] Test with VS Code MCP
- [ ] Test with Gemini CLI

---

## Phase 7: Commit & Push

```bash
git add -A
git commit -m "refactor: rename project from KaliMCPGemini to KaliMCP

- Remove Gemini-specific naming throughout codebase
- Rename project directory and namespace
- Update Docker image name: kali-mcp-gemini → kali-mcp  
- Update container name: kali-mcp-gemini-persistent → kali-mcp-persistent
- Update all config files and documentation

BREAKING CHANGE: Users must rebuild Docker image with new name"

git push
```

- [ ] Commit changes
- [ ] Push to remote

---

## Optional: Rename GitHub Repository

1. Go to GitHub repo → Settings → General
2. Change repository name: `kali-mcp-server-gemini-cli` → `kali-mcp-server`
3. Update local remote:
   ```bash
   git remote set-url origin https://github.com/timsonner/kali-mcp-server.git
   ```

- [ ] Rename repo on GitHub
- [ ] Update local git remote

---

## What Stays the Same

| Item | Reason |
|------|--------|
| `.gemini/` folder | Required location for Gemini CLI config |
| `.gemini/settings.json` file | Just update image name inside |
| `.gitignore` entry for `.gemini/tmp/` | Gemini CLI creates temp files there |
| `GEMINI_SETTINGS_PATH` env var | Optional to rename, low priority |
| Volume name `kali_mcp_data` | Can keep (data persists) or rename |
| "Gemini CLI" section in README | It's the product name, not project name |

---

## Rollback Plan

If something breaks:

```bash
# Revert git changes
git checkout .
git clean -fd

# Rebuild old image
docker build -t kali-mcp-gemini .
```

---

**Delete this file after refactor is complete.**
