#!/bin/bash

# Define the interfaces you want to display
INTERFACES=("enp1s0f0" "enp1s0f1") # Customize this list as needed

# Define colors
PURPLE='\033[38;5;135m'
NC='\033[0m' # No Color
BOLD='\033[1m'
RED='\033[1;31m'

pad() {
  local text="$1"
  local padding=25
  local total_length=$((padding - ${#text}))
  printf "%s" "$text"
  printf "${NC}%0.s." $(seq 1 $total_length)
  printf "${NC}:"
}

human_readable() {
  local value=$1
  if [[ $value -lt 1000 ]]; then
    echo "${value}bps"
  elif [[ $value -lt 1000000 ]]; then
    echo "$(bc <<< "scale=2; $value/1000") Kbps"
  elif [[ $value -lt 1000000000 ]]; then
    echo "$(bc <<< "scale=2; $value/1000000") Mbps"
  else
    echo "$(bc <<< "scale=2; $value/1000000000") Gbps"
  fi
}

interface_statistics() {
  local iface=$1
  local rx_bytes1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
  local tx_bytes1=$(cat /sys/class/net/$iface/statistics/tx_bytes)
  sleep 1
  local rx_bytes2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
  local tx_bytes2=$(cat /sys/class/net/$iface/statistics/tx_bytes)

  local rx_rate=$((($rx_bytes2 - $rx_bytes1) * 8))
  local tx_rate=$((($tx_bytes2 - $tx_bytes1) * 8))

  echo "RX: $(human_readable $rx_rate) / TX: $(human_readable $tx_rate)"
}

# Define the path to the ASCII art file
ascii_art_file="/root/rtr-pve-motd/ascii_art.txt"

# Display ASCII Art from the defined location
if [ -f "$ascii_art_file" ]; then
    cat "$ascii_art_file" | lolcat
else
    echo "ASCII Art file not found."
fi

echo ""
echo -e "${PURPLE}${BOLD}System Information${NC}"
echo "======================"
echo ""

# System Identification
echo -e "${NC}${BOLD}System Type:${NC} ${PURPLE}Proxmox Node${NC}"
echo ""

# Check for updates
updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

if [ "$updates" -gt 0 ]; then
    echo -e "${RED}${BOLD}Updates available: $updates package(s). Run 'apt update'${NC}"
    echo ""
fi

# System Information
if command -v lsb_release &> /dev/null; then
  distro=$(lsb_release -ds)
else
  distro=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d \")
fi
kernel=$(uname -r)

echo -e "${PURPLE}$(pad "Distribution")${NC} $distro"
echo -e "${PURPLE}$(pad "Kernel")${NC} $kernel"
echo ""

# Uptime, Load, Processes
uptime_info=$(uptime -p)
load=$(cat /proc/loadavg)
load_1=$(echo $load | cut -d " " -f1)
load_5=$(echo $load | cut -d " " -f2)
load_15=$(echo $load | cut -d " " -f3)
processes=$(ps -e | wc -l)

echo -e "${PURPLE}$(pad "Uptime")${NC} $uptime_info"
echo -e "${PURPLE}$(pad "Load (1m)")${NC} $load_1"
echo -e "${PURPLE}$(pad "Load (5m)")${NC} $load_5"
echo -e "${PURPLE}$(pad "Load (15m)")${NC} $load_15"
echo -e "${PURPLE}$(pad "Processes")${NC} $processes"
echo ""

# CPU and Memory Usage
cpu_info=$(grep -m 1 'model name' /proc/cpuinfo | cut -d ':' -f 2 | xargs)
mem_total=$(free -h | grep Mem: | awk '{print $2}' | sed 's/Gi/G/')
mem_used=$(free -h | grep Mem: | awk '{print $3}' | sed 's/Gi/G/')
mem_free=$(free -h | grep Mem: | awk '{print $4}' | sed 's/Gi/G/')

echo -e "${PURPLE}$(pad "CPU")${NC} $cpu_info"
echo -e "${PURPLE}$(pad "Mem Used")${NC} $mem_used"
echo -e "${PURPLE}$(pad "Mem Available")${NC} $mem_free"
echo -e "${PURPLE}$(pad "Mem Total")${NC} $mem_total"
echo ""

# Disk Usage
disk_usage=$(df -h --total | grep total | awk '{print $3 " used / " $2 " total (" $5 " used)"}')

echo -e "${PURPLE}$(pad "Disk Usage")${NC} $disk_usage"
echo ""

# Proxmox Stats Heading
echo -e "${PURPLE}${BOLD}Proxmox Stats${NC}"
echo "================"
echo ""

# Node-specific VM and Container Statistics using pvesh
node_name=$(hostname)
node_vms=$(pvesh get /nodes/$node_name/qemu --output-format json | jq length)
node_lxcs=$(pvesh get /nodes/$node_name/lxc --output-format json | jq length)
node_kvms=$((node_vms))

echo -e "${PURPLE}$(pad "Node VMs")${NC} ${node_vms:-0}"
echo -e "${PURPLE}$(pad "Node LXC Containers")${NC} ${node_lxcs:-0}"
echo -e "${PURPLE}$(pad "Node KVM VMs")${NC} ${node_kvms:-0}"
echo ""

# Cluster-wide VM and Container Statistics using pvesh
cluster_vms=$(pvesh get /cluster/resources --output-format json | jq '[.[] | select(.type=="qemu")] | length')
cluster_lxcs=$(pvesh get /cluster/resources --output-format json | jq '[.[] | select(.type=="lxc")] | length')
cluster_kvms=$((cluster_vms - cluster_lxcs))

echo -e "${PURPLE}$(pad "Total VMs")${NC} ${cluster_vms:-0}"
echo -e "${PURPLE}$(pad "Total LXC Containers")${NC} ${cluster_lxcs:-0}"
echo -e "${PURPLE}$(pad "Total KVM VMs")${NC} ${cluster_kvms:-0}"
echo ""

# Interface statistics
echo -e "${PURPLE}${BOLD}Interface Statistics${NC}"
echo "========================"
echo ""
for iface in "${INTERFACES[@]}"; do
    echo -e "${PURPLE}$iface:${NC} $(interface_statistics $iface)\n"
done
echo ""
