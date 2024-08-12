# Custom MOTD Script (Still WIP)

This repository contains a custom script to display system information as the Message of the Day (MOTD) on Linux systems. The script provides detailed system statistics, including CPU usage, memory usage, disk usage, network interfaces, and specialized information for Proxmox nodes and Debian-based routers running BIRD.

## Installation Instructions

To use this script as your system's MOTD, follow the steps below:

### 1. Clone the Repository

Clone this repository to your local machine and install required packages:

```bash
git clone https://github.com/Lostepic/rtr-pve-motd.git
cd rtr-pve-motd
apt install bc ruby jq
gem install lolcat
```
### 2. Run the apply script

```bash
bash apply.sh -rtr (for rtr-motd.sh)
```

### Test the MOTD

```bash
motd
or
summary
```
