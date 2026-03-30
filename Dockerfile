# ============================================================================
# Hermes Agent — Railway Deployment
# Drop this Dockerfile + entrypoint.sh into the root of your forked repo
# ============================================================================

FROM python:3.11-slim AS base

# System deps: git (submodules), nodejs/npm (browser tools, WhatsApp),
# ripgrep (code search), ffmpeg (voice), curl, build essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    nodejs \
    npm \
    ripgrep \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager used by hermes)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# ---------- Build stage ----------
WORKDIR /app

# Copy repo (your fork)
COPY . .

# Init submodules (mini-swe-agent is required for terminal tools)
RUN git init || true
RUN git submodule update --init mini-swe-agent 2>/dev/null || true

# Create venv and install
RUN uv venv venv --python 3.11
ENV VIRTUAL_ENV=/app/venv
ENV PATH="/app/venv/bin:$PATH"

# Core install with all extras (gateway, voice, etc.)
RUN uv pip install -e ".[all]" || uv pip install -e "."

# Terminal backend
RUN if [ -d "mini-swe-agent" ] && [ -f "mini-swe-agent/pyproject.toml" ]; then \
      uv pip install -e "./mini-swe-agent"; \
    fi

# Browser tools + WhatsApp (optional, non-fatal)
RUN npm install 2>/dev/null || true

# Playwright (for browser tools)
RUN npx playwright install --with-deps chromium 2>/dev/null || true

# ---------- Runtime config ----------

# Railway mounts a persistent volume here — memory, skills, config survive redeploys
ENV HERMES_HOME=/data/.hermes
ENV HOME=/data

# Working directory for the agent's terminal commands
ENV MESSAGING_CWD=/data/workspace

# Entrypoint handles first-run bootstrap + config generation from env vars
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
