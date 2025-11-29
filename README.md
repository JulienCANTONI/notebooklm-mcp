<div align="center">

# NotebookLM MCP Server

> **Forked from** [PleasePrompto/notebooklm-mcp](https://github.com/PleasePrompto/notebooklm-mcp)

**Chat directly with NotebookLM for zero-hallucination answers based on your own notebooks**

<!-- Badges -->

[![CI](https://github.com/roomi-fields/notebooklm-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/roomi-fields/notebooklm-mcp/actions/workflows/ci.yml) [![npm version](https://badge.fury.io/js/%40roomi-fields%2Fnotebooklm-mcp.svg)](https://www.npmjs.com/package/@roomi-fields/notebooklm-mcp) [![npm downloads](https://img.shields.io/npm/dm/@roomi-fields/notebooklm-mcp.svg)](https://www.npmjs.com/package/@roomi-fields/notebooklm-mcp) [![codecov](https://codecov.io/gh/roomi-fields/notebooklm-mcp/branch/main/graph/badge.svg)](https://codecov.io/gh/roomi-fields/notebooklm-mcp) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/) [![Node.js](https://img.shields.io/badge/Node.js->=18-green.svg)](https://nodejs.org/)

[![MCP](https://img.shields.io/badge/MCP-2025-green.svg)](https://modelcontextprotocol.io/) [![Claude Code](https://img.shields.io/badge/Claude_Code-MCP-8A2BE2)](https://claude.ai/claude-code) [![n8n](https://img.shields.io/badge/n8n-HTTP_API-orange)](./deployment/docs/04-N8N-INTEGRATION.md) [![GitHub](https://img.shields.io/github/stars/roomi-fields/notebooklm-mcp?style=social)](https://github.com/roomi-fields/notebooklm-mcp)

<!-- End Badges -->

</div>

---

## Why NotebookLM?

| Approach            | Token Cost  | Hallucinations                | Answer Quality       |
| ------------------- | ----------- | ----------------------------- | -------------------- |
| Feed docs to Claude | Very high   | Yes - fills gaps              | Variable             |
| Web search          | Medium      | High - unreliable sources     | Hit or miss          |
| Local RAG           | Medium-High | Medium - retrieval gaps       | Depends on setup     |
| **NotebookLM MCP**  | **Minimal** | **Zero** - refuses if unknown | **Expert synthesis** |

NotebookLM is pre-indexed by Gemini, provides citation-backed answers, and requires no infrastructure.

---

## Quick Start

### Option 1: MCP Mode (Claude Code, Cursor, Codex)

```bash
# Claude Code
claude mcp add notebooklm npx @roomi-fields/notebooklm-mcp@latest

# Cursor - add to ~/.cursor/mcp.json
{
  "mcpServers": {
    "notebooklm": {
      "command": "npx",
      "args": ["-y", "@roomi-fields/notebooklm-mcp@latest"]
    }
  }
}
```

Then say: _"Log me in to NotebookLM"_ → Chrome opens → log in with Google.

### Option 2: HTTP REST API (n8n, Zapier, Make.com)

```bash
git clone https://github.com/roomi-fields/notebooklm-mcp.git
cd notebooklm-mcp
npm install && npm run build
npm run setup-auth   # One-time Google login
npm run start:http   # Start server on port 3000
```

```bash
# Query the API
curl -X POST http://localhost:3000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "Explain X", "notebook_id": "my-notebook"}'
```

---

## Documentation

| Guide                                                        | Description                               |
| ------------------------------------------------------------ | ----------------------------------------- |
| [Installation](./deployment/docs/01-INSTALL.md)              | Step-by-step setup for HTTP and MCP modes |
| [Configuration](./deployment/docs/02-CONFIGURATION.md)       | Environment variables and security        |
| [API Reference](./deployment/docs/03-API.md)                 | Complete HTTP endpoint documentation      |
| [n8n Integration](./deployment/docs/04-N8N-INTEGRATION.md)   | Workflow automation setup                 |
| [Troubleshooting](./deployment/docs/05-TROUBLESHOOTING.md)   | Common issues and solutions               |
| [Notebook Library](./deployment/docs/06-NOTEBOOK-LIBRARY.md) | Multi-notebook management                 |
| [Auto-Discovery](./deployment/docs/07-AUTO-DISCOVERY.md)     | Autonomous metadata generation            |
| [Chrome Limitation](./docs/CHROME_PROFILE_LIMITATION.md)     | HTTP/MCP simultaneous mode issue          |

---

## Core Features

- **Zero Hallucinations** — NotebookLM refuses to answer if info isn't in your docs
- **Multi-Notebook Library** — Manage multiple notebooks with validation and smart selection
- **Auto-Discovery** — Automatically generate metadata via NotebookLM queries
- **HTTP REST API** — Use from n8n, Zapier, Make.com, or any HTTP client
- **Daemon Mode** — Run as background process with PM2 (`npm run daemon:start`)
- **Cross-Tool** — Works with Claude Code, Cursor, Codex, and any MCP client

---

## Architecture

```
Your Task → Agent/n8n → MCP/HTTP Server → Chrome Automation → NotebookLM → Gemini 2.5 → Your Docs
                                                                    ↓
                                                            Accurate Output
```

---

## Roadmap

See [ROADMAP.md](./ROADMAP.md) for planned features and version history.

**Next up (v1.4.0):** Separate Chrome profiles to enable HTTP + MCP modes simultaneously.

---

## Disclaimer

This tool automates browser interactions with NotebookLM. Use a dedicated Google account for automation. CLI tools like Claude Code can make mistakes — always review changes before deploying.

See full [Disclaimer](#disclaimer-details) below.

---

## Contributing

Found a bug? Have an idea? [Open an issue](https://github.com/roomi-fields/notebooklm-mcp/issues) or submit a PR!

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT — Use freely in your projects. See [LICENSE](./LICENSE).

---

<details>
<summary><a name="disclaimer-details"></a>Full Disclaimer</summary>

**About browser automation:**
While I've built in humanization features (realistic typing speeds, natural delays, mouse movements), I can't guarantee Google won't detect or flag automated usage. Use a dedicated Google account for automation.

**About CLI tools and AI agents:**
CLI tools like Claude Code, Codex, and similar AI-powered assistants are powerful but can make mistakes:

- Always review changes before committing or deploying
- Test in safe environments first
- Keep backups of important work
- AI agents are assistants, not infallible oracles

I built this tool for myself and share it hoping it helps others, but I can't take responsibility for any issues that might occur. Use at your own discretion.

</details>

---

<div align="center">

Built with frustration about hallucinated APIs, powered by Google's NotebookLM

⭐ [Star on GitHub](https://github.com/roomi-fields/notebooklm-mcp) if this saves you debugging time!

</div>
