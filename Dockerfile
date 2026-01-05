# NotebookLM MCP Server - Docker Image
#
# Build: docker build -t notebooklm-mcp .
# Run:   docker run -p 3000:3000 -v notebooklm-data:/data notebooklm-mcp

# Use Node.js with Debian for Playwright compatibility
FROM node:20-bookworm-slim

# Install dependencies for Playwright/Chromium
RUN apt-get update && apt-get install -y \
    # Playwright dependencies
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    # Additional utilities
    fonts-liberation \
    fonts-noto-color-emoji \
    wget \
    ca-certificates \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r notebooklm && useradd -r -g notebooklm -d /home/notebooklm notebooklm \
    && mkdir -p /home/notebooklm /app /data \
    && chown -R notebooklm:notebooklm /home/notebooklm /app /data

# Set working directory
WORKDIR /app

# Copy package files first (better caching)
COPY --chown=notebooklm:notebooklm package*.json ./

# Switch to non-root user
USER notebooklm

# Install dependencies (--ignore-scripts to skip husky prepare)
RUN npm ci --omit=dev --ignore-scripts

# Install Playwright browsers (patchright uses same browsers)
RUN npx playwright install chromium

# Copy built application
COPY --chown=notebooklm:notebooklm dist/ ./dist/
COPY --chown=notebooklm:notebooklm package.json ./

# Environment variables
ENV NODE_ENV=production \
    HTTP_PORT=3000 \
    HTTP_HOST=0.0.0.0 \
    HEADLESS=true \
    NOTEBOOKLM_DATA_DIR=/data \
    # Playwright/Chrome settings for Docker
    PLAYWRIGHT_BROWSERS_PATH=/home/notebooklm/.cache/ms-playwright

# Expose HTTP port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Data volume
VOLUME ["/data"]

# Start HTTP server
CMD ["node", "dist/http-wrapper.js"]
