#!/bin/bash

clear

echo "======================================"
echo "        Reverse Tunnel Tester         "
echo "======================================"
echo ""
echo "1) Run as IRAN (Portal - Listener)"
echo "2) Run as OUTSIDE (Bridge - Connector)"
echo ""
read -p "Select mode [1-2]: " MODE

########################################
# IRAN MODE (Portal)
########################################
if [ "$MODE" == "1" ]; then

    read -p "Enter listening port (default 4433): " PORT
    PORT=${PORT:-4433}

    LOG="portal_$(date +%Y%m%d_%H%M%S).log"

    echo -e "\e[32m[✔] Portal started on port $PORT\e[0m"
    echo "[+] Log file: $LOG"

    while true; do
        echo -e "\e[34m[*] Waiting for bridge connection...\e[0m"

        START_TIME=$(date +%s)

        nc -lvnp $PORT 2>/dev/null | while read line; do
            NOW=$(date "+%Y-%m-%d %H:%M:%S")
            echo "[$NOW] $line" | tee -a "$LOG"
        done

        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))

        echo -e "\e[31m[!] Connection closed. Duration: ${DURATION}s\e[0m"
        sleep 2
    done
fi

########################################
# OUTSIDE MODE (Bridge)
########################################
if [ "$MODE" == "2" ]; then

    read -p "Enter Portal IP or Domain: " HOST
    read -p "Enter Port (default 4433): " PORT
    PORT=${PORT:-4433}

    echo -e "\e[32m[✔] Bridge starting...\e[0m"

    while true; do

        echo -e "\e[34m[*] Checking connectivity...\e[0m"

        if ping -c 1 $HOST > /dev/null 2>&1; then
            echo -e "\e[32m[✔] Host reachable\e[0m"
        else
            echo -e "\e[31m[✘] Host unreachable\e[0m"
        fi

        echo -e "\e[34m[*] Connecting to $HOST:$PORT ...\e[0m"

        {
            echo "=== Bridge Connected from $(hostname) ==="
            START=$(date +%s)

            while true; do
                NOW=$(date '+%H:%M:%S')
                echo "Heartbeat | $NOW"
                sleep 5
            done

        } | nc $HOST $PORT

        END=$(date +%s)
        RUNTIME=$((END - START))

        echo -e "\e[31m[!] Disconnected after ${RUNTIME}s\e[0m"
        echo -e "\e[33m[*] Reconnecting in 3 seconds...\e[0m"
        sleep 3
    done
fi
