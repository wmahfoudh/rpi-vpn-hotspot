#!/bin/bash

# Define the default VPN configuration file path
DEFAULT_VPN_CONFIG="default.ovpn"
AUTH_FILE="/path/to/our/files/login.conf"  # Ensure this path is correct

# Check if an argument was provided and use it as the VPN config file; otherwise, use the default
VPN_CONFIG="${1:-$DEFAULT_VPN_CONFIG}"

# Output file for storing logs
OUTPUT_FILE="out.txt"

# Starting VPN with nohup and sending it to the background
nohup openvpn --config $VPN_CONFIG --auth-user-pass $AUTH_FILE --auth-nocache >$OUTPUT_FILE 2>&1 &

echo "VPN started in the background. Logs are being written to $OUTPUT_FILE."

# Wait for the VPN to establish connection
sleep 10

# Fetch and display the public IPv4 address
echo "Fetching public IPv4 address..."
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
echo "Your public IPv4 address is: $PUBLIC_IP"
