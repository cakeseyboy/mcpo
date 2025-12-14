FROM python:3.12-slim-bookworm

# 1. Install uv, nodejs, npm, and git
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Node.js and npm (Critical for Node-based MCP servers)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Setup Workspace
COPY . /app
WORKDIR /app

# --- CRITICAL STEP: Copy your custom config ---
# This ensures 'my_config.json' is baked into the image.
COPY my_config.json /app/my_config.json

# 4. Create Virtual Environment
ENV VIRTUAL_ENV=/app/.venv
RUN uv venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 5. Install mcpo from the source code in this folder
RUN uv pip install . && rm -rf ~/.cache

# 6. Runtime Configuration
# We set PORT default to 8000, but Railway will override this ENV at runtime.
ENV PORT=8000

# We use shell form for CMD so variables like $PORT expand correctly.
# We also explicitly point to the config file we copied in Step 3.
CMD ["sh", "-c", "mcpo --port $PORT --config /app/my_config.json"]
