# Refactor Plan: Remove "Gemini" Naming

**Goal**: Rename project from "Kali MCP Gemini Server" to "Kali MCP Server" to reflect that it's not Gemini-specific.

**Estimated Time**: 15-20 minutes

---

## Pre-Refactor Checklist

- [ ] Commit any pending changes
- [ ] Ensure no active pentest sessions using the container
- [ ] Note any custom tools installed in the container (will be lost if volume is removed)

---

## Phase 1: Rename Project Directory & Files ✅

```bash
# Rename project directory
mv KaliMCPGemini KaliMCP

# Rename .csproj file
mv KaliMCP/KaliMCPGemini.csproj KaliMCP/KaliMCP.csproj
```

- [x] Rename `KaliMCPGemini/` → `KaliMCP/`
- [x] Rename `KaliMCPGemini.csproj` → `KaliMCP.csproj`

---

## Phase 2: Update Source Code ✅

### KaliMCP/Program.cs
- [x] Change namespace `KaliMCPGemini` → `KaliMCP` (no namespace in file, skipped)

### KaliMCP/Tools/KaliLinuxToolset.cs
- [x] Change namespace `KaliMCPGemini.Tools` → `KaliMCP.Tools`
- [x] Change `DefaultContainerName` from `kali-mcp-gemini-persistent` → `kali-mcp-persistent`
- [x] Update all `[Description]` attributes referencing container name

### KaliClient/Program.cs
- [x] Change container name `kali-mcp-gemini-persistent` → `kali-mcp-persistent` (2 occurrences)
- [ ] Optional: Rename `GEMINI_SETTINGS_PATH` → `MCP_SETTINGS_PATH`

---

## Phase 3: Update Build/Runtime Files ✅

### Dockerfile
- [x] `COPY ["KaliMCPGemini/KaliMCPGemini.csproj", "KaliMCPGemini/"]` → `COPY ["KaliMCP/KaliMCP.csproj", "KaliMCP/"]`
- [x] `RUN dotnet restore "KaliMCPGemini/KaliMCPGemini.csproj"` → `RUN dotnet restore "KaliMCP/KaliMCP.csproj"`
- [x] `WORKDIR "/src/KaliMCPGemini"` → `WORKDIR "/src/KaliMCP"`
- [x] `RUN dotnet build "KaliMCPGemini.csproj"` → `RUN dotnet build "KaliMCP.csproj"`
- [x] `RUN dotnet publish "KaliMCPGemini.csproj"` → `RUN dotnet publish "KaliMCP.csproj"`

### entrypoint.sh
- [x] `dotnet KaliMCPGemini.dll` → `dotnet KaliMCP.dll`

### run_mcp.sh
- [x] Update project path from `KaliMCPGemini/KaliMCPGemini.csproj` → `KaliMCP/KaliMCP.csproj`

---

## Phase 4: Update Config Files ✅

### .vscode/mcp.json
- [x] Image name `"kali-mcp-gemini"` → `"kali-mcp"`

### .copilot/mcp-config.json
- [x] Image name `"kali-mcp-gemini"` → `"kali-mcp"`

### .gemini/settings.json (keep file, update contents)
- [x] Image name `"kali-mcp-gemini"` → `"kali-mcp"`

---

## Phase 5: Update Documentation ✅

### README.md (~50 replacements)
- [x] Title: "Kali MCP Gemini Server" → "Kali MCP Server"
- [x] Description: Remove "for Gemini agents" → "for AI agents"
- [x] Project structure: `KaliMCPGemini/` references
- [x] All `kali-mcp-gemini` → `kali-mcp` (image name)
- [x] All `kali-mcp-gemini-persistent` → `kali-mcp-persistent` (container name)
- [x] Keep `.gemini/` folder references as-is
- [x] Keep "Gemini CLI" section name (it's the product name)

### .github/copilot-instructions.md (~20 replacements)
- [x] Title and references to project name
- [x] `KaliMCPGemini/` → `KaliMCP/`
- [x] Container/image names

### .gitignore
- [x] Keep `.gemini/tmp/` as-is (Gemini CLI requirement)

---

## Phase 5.5: Simplify Container Name ✅

Rename nested container from `kali-mcp-persistent` to `kali-mcp-container` for clarity.

### Files Updated
- [x] `KaliMCP/Tools/KaliLinuxToolset.cs` - `DefaultContainerName` constant + 4 `[Description]` attributes
- [x] `KaliClient/Program.cs` - 2 occurrences
- [x] `README.md` - 10 occurrences
- [x] `.github/copilot-instructions.md` - 2 occurrences

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

- [x] Stop and remove old containers
- [x] Decide: Keep or remove `kali_mcp_data` volume (removed)
- [x] Remove old Docker image
- [x] Build new Docker image as `kali-mcp`
- [x] Copy updated config to `~/.copilot/`
- [x] Test with KaliClient
- [x] Test with VS Code MCP
- [x] Test with Gemini CLI

---

## Phase 7: Commit & Push

```bash
git add -A
git commit -m "refactor: rename project from KaliMCPGemini to KaliMCP

- Remove Gemini-specific naming throughout codebase
- Rename project directory and namespace
- Update Docker image name: kali-mcp-gemini → kali-mcp  
- Update container name: kali-mcp-gemini-persistent → kali-mcp-container
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
