#!/bin/bash

VERSION="3.2"

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
# OUTSIDE MODE
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

        # Ping Test
        PING=$(ping -c 3 -W 2 $HOST 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo -e "\e[31m[✘] Host unreachable (No route / Blocked)\e[0m"
            continue
        fi

        LOSS=$(echo "$PING" | grep -oP '\d+(?=% packet loss)')
        LAT=$(echo "$PING" | tail -1 | awk -F '/' '{print $5}')
        LAT=${LAT:-9999}
        echo "Packet Loss: $LOSS% | Avg Latency: ${LAT} ms"

        # TCP Test with diagnostics
        timeout 3 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null
        TCP_STATUS=$?
        if [ $TCP_STATUS -ne 0 ]; then
            echo -e "\e[31m[✘] TCP Port $PORT Closed or Filtered\e[0m"

            # Extra diagnostics
            echo -e "\e[33m[*] Checking route with traceroute...\e[0m"
            traceroute -m 5 $HOST
            continue
        else
            echo -e "\e[32m[✔] TCP Open\e[0m"
        fi

        # Choose best host based on latency
        if [ "$LAT" -lt "$BEST_LAT" ]; then
            BEST_LAT=$LAT
            BEST_HOST=$HOST
        fi
    done

    if [ -z "$BEST_HOST" ]; then
        echo -e "\e[31m[✘] No available targets found.\e[0m"
        exit 1
    fi

    echo ""
    echo -e "\e[32m[✔] Best target selected: $BEST_HOST (Latency: ${BEST_LAT} ms)\e[0m"
    echo ""

    # Connection Loop
    while true; do
        echo -e "\e[34m[*] Connecting to $BEST_HOST:$PORT\e[0m"

        {
            echo "=== Connected from $(hostname) ==="
            START=$(date +%s)
            while true; do
                NOW=$(date '+%H:%M:%S')
                echo "Heartbeat | $NOW"
                sleep 5
            done
        } | nc $BEST_HOST $PORT

        END=$(date +%s)
        RUNTIME=$((END-START))

        echo -e "\e[31m[!] Disconnected after ${RUNTIME}s\e[0m"
        echo -e "\e[33m[*] Re-scanning targets in 3 seconds...\e[0m"
        sleep 3
        exec "$0"
    done
fi
