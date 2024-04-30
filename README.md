# Setting up a VPN Hotspot on the Raspberry PI
This repository provides a way of configuring the Raspberry Pi as a VPN gateway and wireless access point using command-line interface of a minimal Raspbian OS. This guide details the processes for installing and configuring OpenVPN, setting up a secondary wireless network interface as a Wi-Fi hotspot, and integrating.
This setup is tested on the Raspberry Pi 3b, it should work on any vanilla Raspbian, connected preferably with a static IP address and accessible through ssh for convenience. 
## Installing OpenVPN
````
sudo apt update
sudo apt upgrade
sudo apt install openvpn openresolv
````
We will install openvpn as well as openresolv.
### What is OpenVPN?
OpenVPN is a robust and highly configurable VPN solution that allows secure point-to-point or site-to-site connections with routed or bridged configurations and remote access facilities. It uses SSL/TLS for key exchange and is capable of traversing network address translators (NATs) and firewalls.
### Why openresolv?
openresolv is a utility to manage resolv.conf, which is the configuration file for DNS resolvers in Unix-like systems. It allows multiple programs that need to modify resolv.conf to do so safely and flexibly. Programs like VPN clients can dynamically update DNS settings without conflicting with each other. It handles DNS requests properly, protecting against DNS leaks.
