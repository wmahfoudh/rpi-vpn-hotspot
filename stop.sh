#!/bin/bash

# Find the PID of OpenVPN
PID=$(ps aux | grep '[o]penvpn' | awk '{print $2}')

# Kill the OpenVPN process
if [[ -n $PID ]]; then
    echo "Stopping OpenVPN process with PID: $PID"
    sudo kill -9 $PID
    echo "OpenVPN disconnected."
else
    echo "No OpenVPN process found."
fi
