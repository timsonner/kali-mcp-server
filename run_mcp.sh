#!/bin/bash
# Runs the Kali MCP Gemini server.
# Ensure you have Docker running and .NET 9.0 SDK installed.

# Get the absolute path to the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the project
dotnet run --project "$PROJECT_DIR/KaliMCPGemini/KaliMCPGemini.csproj"
