#!/bin/bash
# Launch a new Nanobot instance for a user
# Usage: ./launch-instance.sh <username> <web_port> <ws_port> <gateway_port>
# Example: ./launch-instance.sh alice 8088 8765 18790

set -e

USERNAME=$1
WEB_PORT=$2
WS_PORT=$3
GW_PORT=$4

if [ -z "$USERNAME" ] || [ -z "$WEB_PORT" ] || [ -z "$WS_PORT" ] || [ -z "$GW_PORT" ]; then
    echo "Usage: $0 <username> <web_port> <ws_port> <gateway_port>"
    echo "Example: $0 alice 8088 8765 18790"
    exit 1
fi

CONTAINER_NAME="nanobot-${USERNAME}"
CONFIG_DIR="${HOME}/.nanobot-${USERNAME}"
SECRET=$(openssl rand -hex 24)

# Create config directory
mkdir -p "${CONFIG_DIR}"

# Generate config.json if not exists
if [ ! -f "${CONFIG_DIR}/config.json" ]; then
    cat > "${CONFIG_DIR}/config.json" << EOF
{
  "gateway": {"host": "0.0.0.0", "port": ${GW_PORT}},
  "channels": {
    "websocket": {
      "enabled": true,
      "host": "0.0.0.0",
      "port": ${WS_PORT},
      "tokenIssueSecret": "${SECRET}",
      "extract_document_text": false
    }
  },
  "agents": {
    "defaults": {
      "model": "MiniMax-M3",
      "provider": "minimax",
      "workspace": "~/.nanobot-${USERNAME}/workspace",
      "timezone": "Asia/Shanghai",
      "max_tokens": 8192
    }
  },
  "providers": {
    "minimax": {
      "api_key": "\${MINIMAX_API_KEY}",
      "api_base": "https://api.minimaxi.com/v1"
    }
  }
}
EOF
    echo "Config created at ${CONFIG_DIR}/config.json"
    echo "Token secret: ${SECRET}"
fi

# Run container
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --cap-add SYS_ADMIN \
    --security-opt apparmor=unconfined \
    --security-opt seccomp=unconfined \
    -p ${WEB_PORT}:${WS_PORT} \
    -p ${GW_PORT}:${GW_PORT} \
    -v "${CONFIG_DIR}:/home/nanobot/.nanobot" \
    -e HTTP_PROXY="${HTTP_PROXY:-}" \
    -e HTTPS_PROXY="${HTTPS_PROXY:-}" \
    -e TAVILY_API_KEY="${TAVILY_API_KEY:-}" \
    nanobot-gateway:latest gateway

echo ""
echo "=== Instance ${USERNAME} launched ==="
echo "Container: ${CONTAINER_NAME}"
echo "Web UI:    http://$(hostname -I | awk '{print $1}'):${WEB_PORT}"
echo "Config:    ${CONFIG_DIR}/config.json"
echo "Secret:    ${SECRET}"
echo ""
echo "Add to nginx:"
echo "  server { listen ${WEB_PORT}; location / { proxy_pass http://127.0.0.1:${WS_PORT}; ... } }"
