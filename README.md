# Setting up a VPN Hotspot on the Raspberry PI
This repository provides a way of configuring the Raspberry Pi as a VPN gateway and wireless access point using command-line interface of a minimal Raspbian OS. This guide details the processes for installing and configuring OpenVPN, setting up a secondary wireless network interface as a Wi-Fi hotspot, and integrating.
This setup is tested on the Raspberry Pi 3b, it should work on any vanilla Raspbian, connected preferably with a static IP address and accessible through ssh for convenience. 
## Installing OpenVPN
````
sudo apt update
sudo apt upgrade
sudo apt install openvpn openresolv
````
We will install `openvpn` as well as `openresolv`.
