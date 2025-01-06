#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color (reset the color)

# Function to show a progress bar
progress_bar() {
    local duration=$1
    local bar='##################################################'
    local width=50
    local step=$((duration / width))
    
    for i in $(seq 1 $width); do
        sleep $step
        echo -ne "${bar:0:i}$i/$width\r"
    done
    echo -ne "\n"
}

# Find the PID of OpenVPN
echo -e "${YELLOW}Searching for the OpenVPN process...${NC}"
progress_bar 3  # Simulate a 3-second search duration
PID=$(ps aux | grep '[o]penvpn' | awk '{print $2}')

# Kill the OpenVPN process
if [[ -n $PID ]]; then
    echo -e "${YELLOW}Stopping the OpenVPN process with PID: $PID${NC}"
    
    # Progress bar while trying to kill the process
    progress_bar 2  # Simulate 2 seconds to kill the process
    if sudo kill -9 $PID; then
        echo -e "${GREEN}OpenVPN disconnected.${NC}"
    else
        echo -e "${RED}Failed to stop the OpenVPN process.${NC}"
    fi
else
    echo -e "${RED}No OpenVPN process found.${NC}"
fi
