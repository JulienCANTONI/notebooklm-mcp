# Multi-Interface Mode (v1.3.6+)

> Run Claude Desktop AND HTTP API simultaneously with a single Chrome instance

---

## Overview

The **Stdio-HTTP Proxy** enables Claude Desktop to communicate with the HTTP server, solving the Chrome profile locking issue without requiring separate browser profiles.

```
┌─────────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Claude Desktop ─────► Stdio-HTTP Proxy ────┐                   │
│                        (no Chrome)          │                   │
│                                             ▼                   │
│  n8n / Zapier ──────────────────────► HTTP Server ──► Chrome    │
│                                             │                   │
│  curl / Postman ────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Benefits:**

- ✅ Single Chrome instance (no profile conflicts)
- ✅ Shared authentication state
- ✅ Claude Desktop + HTTP API running simultaneously
- ✅ No additional disk space for separate profiles

---

## Quick Start

### Step 1: Start the HTTP Server

```bash
cd /path/to/notebooklm-mcp-http

# Build if needed
npm run build

# Start HTTP server (owns Chrome)
npm run start:http
# Or as daemon: npm run daemon:start
```

### Step 2: Configure Claude Desktop

Edit your Claude Desktop config file:

**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Linux:** `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "notebooklm": {
      "command": "node",
      "args": ["D:/Claude/notebooklm-mcp-http/dist/stdio-http-proxy.js"],
      "env": {
        "MCP_HTTP_URL": "http://localhost:3000"
      }
    }
  }
}
```

> **Note:** Replace the path with your actual installation path.

### Step 3: Restart Claude Desktop

Close and reopen Claude Desktop. The proxy will connect to your HTTP server.

---

## Configuration Options

### Environment Variables

| Variable       | Default                 | Description          |
| -------------- | ----------------------- | -------------------- |
| `MCP_HTTP_URL` | `http://localhost:3000` | HTTP server URL      |
| `HTTP_PORT`    | `3000`                  | Port for HTTP server |
| `HTTP_HOST`    | `0.0.0.0`               | Host for HTTP server |

### Custom Port Example

```bash
# Terminal 1: HTTP server on port 4000
HTTP_PORT=4000 npm run start:http

# Claude Desktop config
{
  "mcpServers": {
    "notebooklm": {
      "command": "node",
      "args": ["/path/to/dist/stdio-http-proxy.js"],
      "env": {
        "MCP_HTTP_URL": "http://localhost:4000"
      }
    }
  }
}
```

---

## NPM Scripts

| Script         | Description                      |
| -------------- | -------------------------------- |
| `start:http`   | Start HTTP server (foreground)   |
| `start:proxy`  | Start stdio proxy (for testing)  |
| `daemon:start` | Start HTTP server as PM2 daemon  |
| `daemon:stop`  | Stop PM2 daemon                  |
| `daemon:logs`  | View daemon logs                 |
| `dev:http`     | Development mode with hot reload |
| `dev:proxy`    | Development mode for proxy       |

---

## Usage Scenarios

### Scenario 1: Claude Desktop Only (via Proxy)

```bash
# Start HTTP server
npm run daemon:start

# Configure Claude Desktop with proxy (see above)
# Use Claude Desktop normally
```

### Scenario 2: HTTP API Only (n8n, Zapier)

```bash
# Start HTTP server
npm run start:http

# Use HTTP API
curl -X POST http://localhost:3000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is X?", "notebook_id": "my-notebook"}'
```

### Scenario 3: Both Simultaneously

```bash
# Terminal 1: HTTP server (owns Chrome)
npm run daemon:start

# Claude Desktop: uses proxy (configured above)
# n8n/Zapier: uses HTTP API directly
# Both work simultaneously!
```

---

## Troubleshooting

### Proxy can't connect to HTTP server

```
Cannot connect to HTTP server at http://localhost:3000
```

**Solution:** Ensure HTTP server is running:

```bash
npm run daemon:status  # Check if running
npm run daemon:start   # Start if not
```

### Authentication issues

The HTTP server manages authentication. If you need to re-authenticate:

```bash
# Via HTTP API
curl -X POST http://localhost:3000/setup-auth

# Or use Claude Desktop (via proxy)
# Ask: "Setup NotebookLM authentication"
```

### WSL Users

For WSL, the HTTP server must run on Windows (for Chrome access). Use the proxy from WSL:

```bash
# In WSL, point to Windows localhost
export MCP_HTTP_URL="http://localhost:3000"
node /mnt/d/Claude/notebooklm-mcp-http/dist/stdio-http-proxy.js
```

Or configure Claude Desktop on Windows with the proxy.

---

## Comparison: Proxy vs Native Stdio

| Feature              | Native Stdio       | Stdio-HTTP Proxy     |
| -------------------- | ------------------ | -------------------- |
| Chrome instance      | Own instance       | Uses HTTP server's   |
| Run with HTTP server | ❌ Chrome conflict | ✅ Works             |
| Authentication       | Own profile        | Shared with HTTP     |
| Dependencies         | Full (Playwright)  | Minimal (fetch only) |
| Latency              | Direct             | +1 HTTP hop          |
| Use case             | Standalone         | Multi-interface      |

---

## Future: Multi-Profile Mode (v1.4.0)

The multi-profile feature (separate Chrome profiles per mode) is planned for v1.4.0 but is a **separate feature** from multi-interface:

- **Multi-Interface (v1.3.6):** Single Chrome, multiple clients via proxy
- **Multi-Profile (v1.4.0):** Multiple Chrome profiles for independent auth

Most users should use the proxy approach for simplicity.

---

## See Also

- [Installation Guide](./01-INSTALL.md)
- [API Reference](./03-API.md)
- [Chrome Limitation](../../docs/CHROME_PROFILE_LIMITATION.md)
- [WSL Usage](./08-WSL-USAGE.md)
