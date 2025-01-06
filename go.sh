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

# Define the default VPN configuration file path
DEFAULT_VPN_CONFIG="default.ovpn"
AUTH_FILE="login.conf"  # Ensure this path is correct

# Check if an argument was provided and use it as the VPN config file; otherwise, use the default
VPN_CONFIG="${1:-$DEFAULT_VPN_CONFIG}"

# Output file for storing logs
OUTPUT_FILE="out.txt"

# Check if the VPN configuration file exists
if [ ! -f "$VPN_CONFIG" ]; then
    echo -e "${RED}Error: VPN configuration file '$VPN_CONFIG' not found.${NC}" | tee -a "$OUTPUT_FILE"
    exit 1
fi

# Check if the authentication file exists
if [ ! -f "$AUTH_FILE" ]; then
    echo -e "${RED}Error: Authentication file '$AUTH_FILE' not found.${NC}" | tee -a "$OUTPUT_FILE"
    exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed. Please install it to proceed.${NC}" | tee -a "$OUTPUT_FILE"
    exit 1
fi

# Starting VPN with nohup and sending it to the background
echo -e "${YELLOW}Starting VPN in the background...${NC}"
progress_bar 3  # Simulate a 3-second progress bar for starting the VPN
nohup openvpn --config "$VPN_CONFIG" --auth-user-pass "$AUTH_FILE" --auth-nocache > "$OUTPUT_FILE" 2>&1 &
VPN_PID=$!

# Wait a few seconds to give time for the VPN to start
sleep 3

# Check if the VPN process started successfully
if ! ps -p $VPN_PID > /dev/null; then
    echo -e "${RED}Error: VPN process failed to start.${NC}" | tee -a "$OUTPUT_FILE"
    exit 1
fi

echo -e "${GREEN}VPN started in the background. Logs are being written to $OUTPUT_FILE.${NC}"

# Wait for the VPN to establish connection
echo -e "${YELLOW}Waiting for the VPN connection to establish...${NC}"
progress_bar 10  # Simulate a 10-second wait for VPN to connect

# Fetch and display the public IPv4 address
echo -e "${YELLOW}Fetching public IPv4 address...${NC}"
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)

if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}Error: Could not retrieve the public IP address.${NC}" | tee -a "$OUTPUT_FILE"
    exit 1
fi

echo -e "${GREEN}Your public IPv4 address is: $PUBLIC_IP${NC}" | tee -a "$OUTPUT_FILE"
