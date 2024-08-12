# Custom MOTD Script (Still WIP)

This repository contains a custom script to display system information as the Message of the Day (MOTD) on Linux systems. The script provides detailed system statistics, including CPU usage, memory usage, disk usage, network interfaces, and specialized information for Proxmox nodes and Debian-based routers running BIRD.

## Features

- Displays system information such as distribution, kernel version, uptime, load averages, and process count.
- Shows CPU and memory usage.
- Displays disk usage statistics.
- Provides detailed information for Proxmox nodes, including running VMs and storage usage.
- Shows BIRD routing daemon statistics, including active protocols, total routes (IPv4 and IPv6), and memory usage.
- Lists network interfaces and their associated IP addresses.
- Counts GRE tunnels if any are configured.

## Installation Instructions

To use this script as your system's MOTD, follow the steps below:

### 1. Clone the Repository

Clone this repository to your local machine and install required packages:

```bash
git clone https://github.com/Lostepic/rtr-pve-motd.git
cd rtr-pve-motd
apt install bc
```
### 2. Copy the Script to the Appropriate Directory

```bash
sudo cp custom-motd.sh /etc/update-motd.d/99-custom-motd
sudo chmod +x /etc/update-motd.d/99-custom-motd
```
### 3. (Optional) Disable Default MOTD Scripts

```bash
sudo chmod -x /etc/update-motd.d/*
sudo chmod +x /etc/update-motd.d/99-custom-motd
```
### Test the MOTD

```bash
run-parts /etc/update-motd.d/
```
