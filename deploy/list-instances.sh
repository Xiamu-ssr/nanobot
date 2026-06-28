#!/bin/bash
# List all running Nanobot instances
echo "=== Nanobot Instances ==="
echo ""
printf "%-15s %-20s %-10s %-10s %-10s %-10s\n" "USER" "CONTAINER" "WEB_PORT" "WS_PORT" "GW_PORT" "MEM"
printf "%-15s %-20s %-10s %-10s %-10s %-10s\n" "----" "--------" "-------" "-------" "-------" "---"

for c in $(docker ps --filter "name=nanobot-" --format "{{.Names}}" | grep -v "^nanobot-gateway$" | sort); do
    USERNAME=${c#nanobot-}
    PORTS=$(docker port $c 2>/dev/null | grep -oE '[0-9]+->' | sed 's/->//' | tr '\n' ' ')
    MEM=$(docker stats $c --no-stream --format "{{.MemUsage}}" 2>/dev/null | cut -d'/' -f1 | tr -d ' ')
    printf "%-15s %-20s %-10s %-10s %-10s %-10s\n" "$USERNAME" "$c" "$(echo $PORTS | awk '{print $1}')" "$(echo $PORTS | awk '{print $2}')" "$(echo $PORTS | awk '{print $3}')" "$MEM"
done
