#!/bin/bash
set -e

RICK_HOME="${RICK_HOME:-/home/rick}"
RICK_CONFIG_DIR="$RICK_HOME/.rick"
WORKSPACE_DIR="${WORKSPACE_DIR:-/data/workspace/startup-factory}"

# Ensure required dirs
mkdir -p "$RICK_CONFIG_DIR"/{sessions,memories,skills,cron,backups}

# Defaults
RICK_MODEL="${RICK_MODEL:-minimax/minimax-m2.7}"
RICK_INFERENCE_PROVIDER="${RICK_INFERENCE_PROVIDER:-openrouter}"
RICK_GATEWAY_PORT="${RICK_GATEWAY_PORT:-18791}"
DISCORD_ALLOWED_USERS="${DISCORD_ALLOWED_USERS:-588858125126336544,1484966987321835733}"
DISCORD_REQUIRE_MENTION="${DISCORD_REQUIRE_MENTION:-false}"
DISCORD_FREE_RESPONSE_CHANNELS="${DISCORD_FREE_RESPONSE_CHANNELS:-1489982401445888000,1489982424594251920,1484900474363842643}"

echo "[rick] Starting Startup Factory OS agent..."
echo "[rick] Model: $RICK_MODEL @ $RICK_INFERENCE_PROVIDER"
echo "[rick] Gateway port: $RICK_GATEWAY_PORT"
echo "[rick] Workspace: $WORKSPACE_DIR"

# Write config.yaml
cat > "$RICK_CONFIG_DIR/config.yaml" << CFGEOF
model:
  default: "${RICK_MODEL}"
  provider: "${RICK_INFERENCE_PROVIDER}"
  base_url: "https://openrouter.ai/api/v1"
CFGEOF

# Write .env
cat > "$RICK_CONFIG_DIR/.env" << ENVEOF
RICK_MODEL=${RICK_MODEL}
RICK_INFERENCE_PROVIDER=${RICK_INFERENCE_PROVIDER}
RICK_GATEWAY_PORT=${RICK_GATEWAY_PORT}
DISCORD_ALLOWED_USERS=${DISCORD_ALLOWED_USERS}
DISCORD_REQUIRE_MENTION=${DISCORD_REQUIRE_MENTION}
DISCORD_FREE_RESPONSE_CHANNELS=${DISCORD_FREE_RESPONSE_CHANNELS}
TEMPORAL_ADDRESS=${TEMPORAL_ADDRESS:-temporal:7233}
TEMPORAL_NAMESPACE=${TEMPORAL_NAMESPACE:-default}
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN:-}
BOT_COORDINATION_DB_HOST=${BOT_COORDINATION_DB_HOST:-x0k4w8404wckwwcswg808gco}
BOT_COORDINATION_DB_PORT=${BOT_COORDINATION_DB_PORT:-5432}
BOT_COORDINATION_DB_USER=${BOT_COORDINATION_DB_USER:-postgres}
BOT_COORDINATION_DB_PASS=${BOT_COORDINATION_DB_PASS:-WFBGCo6cjCf7NbxVfkPSe5x0P41v3d27MowubhpPmfk9CgrfcMhBUvp8lyCfjobL}
BOT_COORDINATION_DB_NAME=${BOT_COORDINATION_DB_NAME:-projects}
POSTGRES_MCP_DATABASE_URL=${POSTGRES_MCP_DATABASE_URL:-postgres://postgres:WFBGCo6cjCf7NbxVfkPSe5x0P41v3d27MowubhpPmfk9CgrfcMhBUvp8lyCfjobL@x0k4w8404wckwwcswg808gco:5432/postgres}
PROJECTS_MCP_DATABASE_URL=${PROJECTS_MCP_DATABASE_URL:-postgres://postgres:WFBGCo6cjCf7NbxVfkPSe5x0P41v3d27MowubhpPmfk9CgrfcMhBUvp8lyCfjobL@x0k4w8404wckwwcswg808gco:5432/projects}
ENVEOF

echo "[rick] Config written."

# Git sync workspace if URL provided
if [ -n "$WORKSPACE_GIT_URL" ]; then
    echo "[rick] Syncing workspace from git: $WORKSPACE_GIT_URL"
    cd "$WORKSPACE_DIR"
    if [ -d ".git" ]; then
        git pull origin main --rebase || true
    else
        git clone "$WORKSPACE_GIT_URL" .
    fi
fi

# Copy SOUL.md if provided
if [ -n "$SOUL_OVERRIDE_URL" ]; then
    echo "[rick] Fetching SOUL.md from: $SOUL_OVERRIDE_URL"
    curl -sL "$SOUL_OVERRIDE_URL" -o "$RICK_HOME/SOUL.md"
fi

# Start OpenClaw gateway
echo "[rick] Starting OpenClaw gateway on port $RICK_GATEWAY_PORT..."

exec /opt/openclaw/openclaw-gateway \
    --port "$RICK_GATEWAY_PORT" \
    --workspace "$WORKSPACE_DIR" \
    --config-dir "$RICK_CONFIG_DIR" \
    --model "$RICK_MODEL" \
    --inference-provider "$RICK_INFERENCE_PROVIDER" \
    --discord-bot-token "$DISCORD_BOT_TOKEN" \
    --allowed-users "$DISCORD_ALLOWED_USERS"
