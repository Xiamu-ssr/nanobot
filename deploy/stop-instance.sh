#!/bin/bash
# Stop and remove a Nanobot instance
# Usage: ./stop-instance.sh <username>
# Example: ./stop-instance.sh alice

set -e

USERNAME=$1
if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

CONTAINER_NAME="nanobot-${USERNAME}"

echo "Stopping ${CONTAINER_NAME}..."
docker stop "${CONTAINER_NAME}" 2>/dev/null || echo "Container not running"
docker rm "${CONTAINER_NAME}" 2>/dev/null || echo "Container already removed"

echo ""
echo "Instance ${USERNAME} stopped."
echo "Config preserved at ~/.nanobot-${USERNAME}/"
echo "To fully remove: rm -rf ~/.nanobot-${USERNAME}/"
