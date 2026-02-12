#!/bin/bash

VERSION="3.1"

clear
echo "==============================================="
echo "     Reverse Tunnel Monitor v$VERSION"
echo "==============================================="
echo ""
echo "1) IRAN (Portal - Listener)"
echo "2) OUTSIDE (Bridge - Multi Target Monitor)"
echo ""
read -p "Select mode [1-2]: " MODE

########################################
# IRAN MODE
########################################
if [ "$MODE" == "1" ]; then

    read -p "Enter listening port (default 4433): " PORT
    PORT=${PORT:-4433}

    LOG="portal_$(date +%Y%m%d_%H%M%S).log"

    echo -e "\e[32m[✔] Portal started on port $PORT\e[0m"

    while true; do
        START_TIME=$(date +%s)

        nc -lvnp $PORT 2>/dev/null | while read line; do
            NOW=$(date "+%Y-%m-%d %H:%M:%S")
            echo "[$NOW] $line" | tee -a "$LOG"
        done

        END_TIME=$(date +%s)
        echo -e "\e[31m[!] Disconnected after $((END_TIME-START_TIME))s\e[0m"
        sleep 2
    done
fi

########################################
# OUTSIDE MODE (Multi Target + Failover)
########################################
if [ "$MODE" == "2" ]; then

    echo "Enter Portal IPs or Domains (space separated):"
    read TARGETS

    read -p "Enter Port (default 4433): " PORT
    PORT=${PORT:-4433}

    BEST_HOST=""
    BEST_LAT=9999

    echo ""
    echo "========== Network Scan =========="

    for HOST in $TARGETS; do

        echo -e "\e[34m[*] Testing $HOST\e[0m"

        # Ping test
        PING=$(ping -c 3 -W 2 $HOST 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo -e "\e[31m[✘] Unreachable\e[0m"
            continue
        fi

        LOSS=$(echo "$PING
