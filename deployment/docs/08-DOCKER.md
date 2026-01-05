# Docker Deployment

Run NotebookLM MCP Server in a Docker container for isolated, reproducible deployments.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Using Docker CLI

```bash
# Build image
docker build -t notebooklm-mcp .

# Run container
docker run -d \
  --name notebooklm-mcp \
  -p 3000:3000 \
  -v notebooklm-data:/data \
  notebooklm-mcp
```

## First-Time Setup

After starting the container, you need to authenticate with Google:

```bash
# Option 1: Use the setup-auth endpoint
curl -X POST http://localhost:3000/setup-auth \
  -H "Content-Type: application/json" \
  -d '{"show_browser": true}'

# Option 2: Copy existing credentials into the container
docker cp ~/.local/share/notebooklm-mcp/. notebooklm-mcp:/data/
```

**Note:** For initial authentication, you may need to run in non-headless mode or use pre-authenticated credentials.

## Configuration

### Environment Variables

| Variable               | Default   | Description           |
| ---------------------- | --------- | --------------------- |
| `HTTP_PORT`            | `3000`    | HTTP server port      |
| `HTTP_HOST`            | `0.0.0.0` | HTTP server host      |
| `HEADLESS`             | `true`    | Run browser headless  |
| `STEALTH_ENABLED`      | `true`    | Enable anti-detection |
| `NOTEBOOKLM_DATA_DIR`  | `/data`   | Data directory path   |
| `NOTEBOOKLM_UI_LOCALE` | `fr`      | UI language (fr/en)   |
| `AUTO_LOGIN_ENABLED`   | `false`   | Enable auto-login     |

### Custom Configuration

Edit `docker-compose.yml` to customize:

```yaml
environment:
  - HEADLESS=true
  - NOTEBOOKLM_UI_LOCALE=en
  - AUTO_LOGIN_ENABLED=true
```

## Data Persistence

All data is stored in the `/data` volume:

```
/data/
├── library.json          # Notebook library
├── accounts.json         # Account configuration
├── accounts/             # Per-account data
│   └── account-xxx/
│       ├── credentials.enc.json
│       ├── quota.json
│       └── state.json
├── browser_state/        # Browser cookies/state
│   └── state.json
└── chrome_profile/       # Chrome profile data
```

### Backup

```bash
# Backup data volume
docker run --rm \
  -v notebooklm-mcp-data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/notebooklm-backup.tar.gz -C /data .

# Restore
docker run --rm \
  -v notebooklm-mcp-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/notebooklm-backup.tar.gz -C /data
```

## Resource Requirements

| Resource | Minimum | Recommended |
| -------- | ------- | ----------- |
| Memory   | 512 MB  | 2 GB        |
| CPU      | 1 core  | 2 cores     |
| Disk     | 500 MB  | 2 GB        |

Chromium in headless mode uses significant memory. Adjust limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 4G
    reservations:
      memory: 1G
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs notebooklm-mcp

# Check container status
docker ps -a

# Inspect container
docker inspect notebooklm-mcp
```

### Browser issues

If Chromium fails to launch:

1. Ensure sufficient memory (minimum 512MB)
2. Check for missing dependencies in logs
3. Try rebuilding: `docker-compose build --no-cache`

### Authentication issues

```bash
# Check health endpoint
curl http://localhost:3000/health

# If not authenticated, run setup
curl -X POST http://localhost:3000/setup-auth
```

### Permission issues

```bash
# Fix volume permissions
docker run --rm -v notebooklm-mcp-data:/data alpine chown -R 1000:1000 /data
```

## Production Deployment

### With Reverse Proxy (nginx)

```nginx
server {
    listen 80;
    server_name notebooklm.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### With Traefik

```yaml
services:
  notebooklm-mcp:
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.notebooklm.rule=Host(`notebooklm.example.com`)'
      - 'traefik.http.services.notebooklm.loadbalancer.server.port=3000'
```

### Security Considerations

1. **Don't expose port 3000 publicly** - use a reverse proxy with authentication
2. **Use secrets management** for credentials
3. **Regular backups** of the data volume
4. **Monitor container health** using the healthcheck endpoint

## Building Custom Image

```bash
# Build with specific Node version
docker build --build-arg NODE_VERSION=20 -t notebooklm-mcp:custom .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t notebooklm-mcp:multi .
```

## Development Mode

For development with hot reload:

```yaml
# docker-compose.override.yml
version: '3.8'
services:
  notebooklm-mcp:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
      - /app/node_modules
    command: npm run dev:http
```
