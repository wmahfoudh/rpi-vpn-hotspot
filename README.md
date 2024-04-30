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
#### What is `nohup`?
- **Purpose**: The `nohup` command, short for "no hangup," is used to run a command immune to hangups, with the output sent to a non-tty. It's used to run a process in the background that should continue running even if the user logs out.
- **Functionality**: `nohup` prevents the process from receiving a SIGHUP (signal hang up), which is normally sent to a process when its controlling terminal is closed (for example, when the user logs out).
- **Output Redirection**: By default, `nohup` redirects the standard output (stdout) and standard error (stderr) to a file named `nohup.out` if no output redirection is specified. This is useful for capturing the output of the process after disconnecting from the terminal.

#### Why use `&`?
- **Background Execution**: The `&` at the end of a command line in Unix-like systems tells the shell to run the command in the background. This means you can continue using the terminal for other commands while the background process runs.
- **Immediate Return**: Using `&` allows the shell to immediately return to the command prompt without waiting for the command to complete.

#### Combining `nohup` and `&`
- **Continuous Operation**: When combined, `nohup` and `&` allow a process to run continuously in the background, immune to hangups, even after the user has logged out. This is particularly useful for long-running processes on remote servers where the user might need to disconnect.

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
## Hotspot Setup with the VPN
### Installations
```` bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install hostapd dnsmasq iptables-persistent
````
### Plug in the USB WiFi Adapter and identify it
It is better to use a different WiFi adpter to run the Hotspot, we assume this scenario here. Plus it and run `ip a`. We need the name of the interface we will be using for the rest. We assume here it is `wlan1`

### Configure Hostapd
Hostapd will manage your hotspot. You need to create a configuration file for your new adapter:

Create the hostapd configuration file for `wlan1`:
   ```bash
   sudo nano /etc/hostapd/wlan1.conf
   ```
   And add the following configuration:
   ```
   interface=wlan1
   driver=nl80211
   ssid=use-your-illusion
   hw_mode=g
   channel=6
   ieee80211n=1
   wmm_enabled=1
   macaddr_acl=0
   ignore_broadcast_ssid=0
   auth_algs=1
   wpa=2
   wpa_key_mgmt=WPA-PSK
   wpa_pairwise=TKIP
   rsn_pairwise=CCMP
   wpa_passphrase=locomotive
   ```
   Adjust settings like `ssd`, `wpa_passphrase` and `channel` as necessary.
