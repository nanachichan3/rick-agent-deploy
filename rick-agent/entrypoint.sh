#!/bin/bash
set -e

# ============================================================
# Rick — Startup Factory OS Agent Entrypoint
# ============================================================
# Single agent: Rick. Starts OpenClaw gateway + optional cron.

RICK_HOME="${RICK_HOME:-/home/node}"
CONFIG_DIR="${RICK_HOME}/.openclaw"
WORKSPACE_DIR="${WORKSPACE_DIR:-/data/workspace/startup-factory}"
GATEWAY_PORT="${RICK_GATEWAY_PORT:-18791}"

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"

echo "[rick] Starting Startup Factory OS agent..."
echo "[rick] Gateway port: $GATEWAY_PORT"
echo "[rick] Workspace: $WORKSPACE_DIR"

# ── Git sync workspace ──────────────────────────────────────
if [ -n "$WORKSPACE_GIT_URL" ] && [ -d "$WORKSPACE_DIR/.git" ]; then
    echo "[rick] Git syncing workspace..."
    cd "$WORKSPACE_DIR"
    git pull origin main --rebase 2>/dev/null || echo "[rick] Git sync skipped (no changes or not a git repo)"
elif [ -n "$WORKSPACE_GIT_URL" ]; then
    echo "[rick] Cloning workspace: $WORKSPACE_GIT_URL"
    git clone "$WORKSPACE_GIT_URL" "$WORKSPACE_DIR" 2>/dev/null || echo "[rick] Clone failed"
fi

# ── Write agents.json for this single agent ─────────────────
cat > "$CONFIG_DIR/agents.json" << 'AGENTS'
[
  {
    "id": "rick",
    "name": "Rick",
    "default": true,
    "workspace": "/data/workspace/startup-factory"
  }
]
AGENTS

# ── Write .env for DB + Temporal ────────────────────────────
cat > "$CONFIG_DIR/.env" << ENVEOF
RICK_GATEWAY_PORT=${RICK_GATEWAY_PORT:-18791}
DISCORD_ALLOWED_USERS=${DISCORD_ALLOWED_USERS:-588858125126336544,1484966987321835733}
DISCORD_REQUIRE_MENTION=${DISCORD_REQUIRE_MENTION:-false}
DISCORD_FREE_RESPONSE_CHANNELS=${DISCORD_FREE_RESPONSE_CHANNELS:-1489982401445888000,1489982424594251920,1484900474363842643}
TEMPORAL_ADDRESS=${TEMPORAL_ADDRESS:-temporal:7233}
TEMPORAL_NAMESPACE=${TEMPORAL_NAMESPACE:-default}
BOT_COORDINATION_DB_HOST=${BOT_COORDINATION_DB_HOST:-x0k4w8404wckwwcswg808gco}
BOT_COORDINATION_DB_PORT=${BOT_COORDINATION_DB_PORT:-5432}
BOT_COORDINATION_DB_USER=${BOT_COORDINATION_DB_USER:-postgres}
BOT_COORDINATION_DB_PASS=${BOT_COORDINATION_DB_PASS:-WFBGCo6cjCf7NbxVfkPSe5x0P41v3d27MowubhpPmfk9CgrfcMhBUvp8lyCfjobL}
BOT_COORDINATION_DB_NAME=${BOT_COORDINATION_DB_NAME:-projects}
PROJECTS_MCP_DATABASE_URL=${PROJECTS_MCP_DATABASE_URL:-postgres://postgres:WFBGCo6cjCf7NbxVfkPSe5x0P41v3d27MowubhpPmfk9CgrfcMhBUvp8lyCfjobL@x0k4w8404wckwwcswg808gco:5432/projects}
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN:-}
ENVEOF

echo "[rick] Config written to $CONFIG_DIR"

# ── Start OpenClaw gateway ──────────────────────────────────
echo "[rick] Starting gateway on port $GATEWAY_PORT..."

exec node dist/index.js gateway \
    --bind lan \
    --port "$GATEWAY_PORT" \
    --workspace "$WORKSPACE_DIR" \
    --config-dir "$CONFIG_DIR"
