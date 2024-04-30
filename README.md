# Setting up a VPN Hotspot on the Raspberry PI
This repository provides a way of configuring the Raspberry Pi as a VPN gateway and wireless access point using command-line interface of a minimal Raspbian OS. This guide details the processes for installing and configuring OpenVPN, setting up a secondary wireless network interface as a Wi-Fi hotspot, and integrating.
This setup is tested on the Raspberry Pi 3b, it should work on any vanilla Raspbian, connected preferably with a static IP address and accessible through ssh for convenience. 
## Installing OpenVPN
```` bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install openvpn openresolv
````
We will install openvpn as well as openresolv.
### What is OpenVPN?
OpenVPN is a robust and highly configurable VPN solution that allows secure point-to-point or site-to-site connections with routed or bridged configurations and remote access facilities. It uses SSL/TLS for key exchange and is capable of traversing network address translators (NATs) and firewalls.
### Why openresolv?
openresolv is a utility to manage resolv.conf, which is the configuration file for DNS resolvers in Unix-like systems. It allows multiple programs that need to modify resolv.conf to do so safely and flexibly. Programs like VPN clients can dynamically update DNS settings without conflicting with each other. It handles DNS requests properly, **protecting against DNS leaks**.
### Let's make it easier
Tyically, 
- We have multiple OpenVPN connection files `.ovpn`, we chose which one to use
- We connect to Raspberry Pi though ssh and we would like to leave the VPN connected when we close the ssh session

We will create a simple bash script that:
- Takes a `.ovpn` as argument to use it for connection, if not provided it will connect to a default one
- Connects and leave OpenVPN running in the background
- After connecting, it will fetch the external IP address and display it
- Uses a text file called `login.conf` where the OpenVPN username and password are stored to connect without prompt (you can secure this file and make it accessible only to root users, this will work because we will run the scipt as root)
- Logs the output of OpenVPN to a text file `out.txt`
Here we go, 
```` bash
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
````
Let's call this file `go.sh` and make it executable:
```` bash
chmod +x go.sh
````
`login.conf` looks like this:
```` text
username
password
````
To connect to the default VPN:
```` bash
sudo ./go.sh
````
To connect to a specific VPN:
```` bash
sudo ./go.sh another-vpn.ovpn
````
Before we finish, let's create another script `stop.sh` to stop OpenVPN when needed:
```` bash
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
````
## Creating a Hotspot
