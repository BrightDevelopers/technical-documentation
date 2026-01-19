# BrightDeveloper MCP Server Setup Guide

This guide explains how to connect the **BrightDeveloper MCP Server** to your AI coding assistants. The BrightDeveloper MCP server provides access to BrightSign technical documentation, including APIs for BrightSign players, BSN.cloud, BrightScript, and related developer resources.

**MCP Server URL:** `https://brightdeveloper-mcp.bsn.cloud/mcp`

**Transport Type:** Streamable HTTP (`http`)

---

## Table of Contents

1. [Claude Code](#claude-code)
2. [VS Code with GitHub Copilot](#vs-code-with-github-copilot)
3. [Verifying the Connection](#verifying-the-connection)
4. [Troubleshooting](#troubleshooting)

---

## Claude Code

### Quick Setup (Command Line)

Run the following command in your terminal:

```bash
claude mcp add brightdeveloper --transport http https://brightdeveloper-mcp.bsn.cloud/mcp
```

### Manual Setup

If you prefer to edit the configuration file directly:

1. Open your Claude Code configuration file:
   - **macOS/Linux:** `~/.claude.json`
   - **Windows:** `%USERPROFILE%\.claude.json`

2. Add the BrightDeveloper server to the `mcpServers` section:

```json
{
  "mcpServers": {
    "brightdeveloper": {
      "transport": "http",
      "url": "https://brightdeveloper-mcp.bsn.cloud/mcp"
    }
  }
}
```

3. Save the file.

### Verify Installation

```bash
claude mcp list
```

You should see:
```
brightdeveloper: https://brightdeveloper-mcp.bsn.cloud/mcp ( Connected
```

---

## VS Code with GitHub Copilot

### Prerequisites

- VS Code version **1.102** or later
- GitHub Copilot extension installed and enabled
- Agent Mode enabled in Copilot settings

### Option 1: Workspace Configuration (Recommended for Teams)

This method shares the MCP server configuration with your project team.

1. Create or open `.vscode/mcp.json` in your workspace root.

2. Add the following configuration:

```json
{
  "servers": {
    "brightdeveloper": {
      "type": "http",
      "url": "https://brightdeveloper-mcp.bsn.cloud/mcp"
    }
  }
}
```

3. Save the file. VS Code will detect the new server configuration.

4. When prompted, click **Start** to start the MCP server, or use the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run **MCP: List Servers**, then start the server.

### Option 2: User Configuration (Available in All Workspaces)

This method makes the MCP server available across all your VS Code workspaces.

1. Open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).

2. Run **MCP: Add Server**.

3. Select **HTTP** as the server type.

4. Enter the URL: `https://brightdeveloper-mcp.bsn.cloud/mcp`

5. Enter a name: `brightdeveloper`

6. Select **User** to add it to your global configuration.

Alternatively, manually edit your user `mcp.json`:

1. Run **MCP: Open User Configuration** from the Command Palette.

2. Add the server configuration:

```json
{
  "servers": {
    "brightdeveloper": {
      "type": "http",
      "url": "https://brightdeveloper-mcp.bsn.cloud/mcp"
    }
  }
}
```

### Using the MCP Server in Copilot

1. Open the **Chat** view (`Ctrl+Alt+I` / `Cmd+Alt+I`).

2. Select **Agent** mode from the dropdown at the top of the chat.

3. Click the **Tools** icon () to see available MCP tools. You should see tools from the `brightdeveloper` server.

4. Ask questions about BrightSign development:
   - "What APIs are available for BrightSign players?"
   - "How do I use the Local DWS API?"
   - "Show me how to upload content to BSN.cloud programmatically"
   - "What is BrightScript and how do I get started?"

---

## Verifying the Connection

### Test the Server Directly

You can verify the MCP server is responding using curl:

```bash
curl -H "Accept: text/event-stream" https://brightdeveloper-mcp.bsn.cloud/mcp
```

A successful connection will return a JSON-RPC response or begin streaming events.

### In VS Code

1. Run **MCP: List Servers** from the Command Palette.
2. The `brightdeveloper` server should show a green status indicator.
3. Select the server to see available actions like **Show Output** for logs.

### In Claude Code

```bash
claude mcp list
```

Look for a ) next to the brightdeveloper server.

---

## Troubleshooting

### "Failed to connect" Error

**Cause:** Using the wrong transport type.

**Solution:** The BrightDeveloper MCP server uses **Streamable HTTP** transport, not SSE. Make sure your configuration uses:
- Claude Code: `--transport http`
- VS Code: `"type": "http"`

### "Not Acceptable: Client must accept text/event-stream" Error

**Cause:** The client is not sending the correct `Accept` header.

**Solution:** This typically indicates the MCP client is outdated. Update your tools:
- **Claude Code:** `npm update -g @anthropic-ai/claude-code`
- **VS Code:** Update to version 1.102 or later

### Server Not Appearing in Tool List

1. Ensure the MCP server is started (check for the green indicator in VS Code or run `claude mcp list`).
2. Restart the MCP server: In VS Code, use **MCP: List  select  **Restart**.
3. Clear cached tools: Run **MCP: Reset Cached Tools** in VS Code.

### Connection Timeout

The BrightDeveloper MCP server is hosted remotely. Ensure you have:
- A stable internet connection
- No firewall blocking outbound HTTPS connections to `*.bsn.cloud`

---

## What You Can Do With BrightDeveloper MCP

Once connected, you can ask your AI assistant about:

- **Player APIs:** Local DWS (Diagnostic Web Server), JavaScript APIs, BrightScript APIs
- **BSN.cloud:** REST APIs, authentication, content management, device provisioning
- **BrightAuthor:connected:** Creating presentations, publishing content
- **Development:** BrightScript programming, HTML5 app development, debugging
- **Hardware:** Player specifications, GPIO, serial ports, networking

### Example Prompts

```
"How do I authenticate with the BSN.cloud API?"
"Show me an example of controlling a BrightSign player via the Local DWS"
"What JavaScript APIs are available on BrightSign players?"
"How do I create a BrightScript autorun file?"
"What's the difference between BrightScript and JavaScript on BrightSign?"
```

---

## Additional Resources

- [BrightSign Developer Documentation](https://docs.brightsign.biz/developers)
- [BSN.cloud API Documentation](https://docs.brightsign.biz/developers/2025-api-usage-guide)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [VS Code MCP Documentation](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)

---

