# Setting up a VPN + Hotspot on the Raspberry PI
This guide demonstrates how to configure a Raspberry Pi as a VPN gateway and Wi-Fi access point using the command-line interface on Raspbian (with or without desktop environment). It covers the installation and configuration of OpenVPN, the setup of a secondary wireless network interface as a hotspot, and their integration. A noted challenge is the need to use `dhcpcd`, which is the default for Raspbian, so no NetworkManager like in many other Linux distributions (no `nmcli`). This configuration has been tested on the Raspberry Pi 3b and is applicable to any standard Raspbian installation, ideally operated with a static IP on default interface and accessible via SSH.
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

If you are on ProtonVPN, you would like to download and activate its configuration:
````bash
sudo wget "https://raw.githubusercontent.com/ProtonVPN/scripts/master/update-resolv-conf.sh" -O "/etc/openvpn/update-resolv-conf"
sudo chmod +x "/etc/openvpn/update-resolv-conf"
````
To connect to OpenVPN, simply run `your-ovpn-file.ovpn`

### Let's make it fancier
Tyically, 
- We have multiple OpenVPN connection files `.ovpn`, we should be able to choose which one to use
- We connect to Raspberry Pi though SSH and we would like to leave the VPN connected when we close the SSH session

We will create a simple script that:
- Takes a `.ovpn` as argument to use it for connection, if not provided it will connect to a default one
- Connects and leave OpenVPN running in the background
- After connecting, it will fetch the external IP address and display it
- Uses a text file called `login.conf` where the OpenVPN username and password are stored to connect without prompt (you can chmod this file and make it accessible only to root users, this will work because we will run the scipt as root)
- Optionally, logs the output of OpenVPN to a text file `out.txt`

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
It is better to use a different WiFi adpter to run the Hotspot, we assume this scenario here. Plug it and run `ip a`. We need the name of the interface we will be using for the rest. We assume here it is `wlan1`

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
ssid=Locomotive
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
wpa_passphrase=use-your-illusion
```
   Adjust settings like `ssd`, `wpa_passphrase` and `channel` as necessary.

Now, tell Hostapd to use this configuration file by editing its main configuration
````bash
sudo nano /etc/default/hostapd
````
Find the line `#DAEMON_CONF=""` and change it to:
```` bash
DAEMON_CONF="/etc/hostapd/wlan1.conf"
````
### Configure Dnsmasq for DHCP
Dnsmasq will manage IP address distribution for connected devices:

Back up the existing Dnsmasq configuration:
```bash
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
```
   
Create a new configuration:
```bash
sudo nano /etc/dnsmasq.conf
```
Add the following lines:
```
interface=wlan1
dhcp-range=192.168.50.2,192.168.50.100,255.255.255.0,24h
server=8.8.8.8
server=8.8.4.4
```

### Set Up IP Address for wlan1
Configure a static IP for `wlan1`:
````bash
sudo nano /etc/dhcpcd.conf
````

Add to the end:
````
interface wlan1
static ip_address=192.168.50.1/24
nohook wpa_supplicant
static domain_name_servers=8.8.8.8 8.8.4.4
````

### Enable and Start Services
Enable and start `hostapd` and restart `dnsmasq`:
````bash
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo systemctl restart dnsmasq
````

### Enable IP Forwarding and NAT
Edit `sysctl.conf` to enable IP forwarding:
````bash
sudo nano /etc/sysctl.conf
````

Un-comment:
```` bash
net.ipv4.ip_forward=1
````

Apply changes:
````bash
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
````

**The final touch**: When the VPN is connected, it creates a virtual interface (usually `tun0`). Now we need to tell the system how to route the traffic through the interfaces, especially the VPN interface.
If you don't do this, the WiFi hotspot will work, but you won't be able to access the internet even if the Pi is connected.
``` bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
# Important to make it through VPN !
sudo iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```

Remember `iptables-persistent` that we installed in the beginning? That will ensure that our `iptables` rules above are reloaded on boot. We can force this also by running `sudo netfilter-persistent save`

### Reboot
After all the mess we made, we need to reboot
```bash
sudo reboot
```
After reboot, you should be able to see and connect to your new Hotspot. Connect your VPN and voilà!

## VPN Coonection drop issue
I found that the VPN connection drops after long time of inactivity. Editing the `.ovn` file and adding a `keepalive` directive below the servers list helps.
````
client
dev tun
proto udp

remote xx.xx.xx.xx xxxx
remote xx.xx.xx.xx xxxx

keepalive 10 60

server-poll-timeout 20
...
````
This allows sending a ping every 10 seconds and assuming the connection is down if no response is received within 60 seconds, triggering a reconnection if necessary.
