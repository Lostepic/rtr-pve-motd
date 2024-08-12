#!/bin/bash

# Define the interfaces you want to display
INTERFACES=("ens18" "ens19" "ens20" "ens21" "ens22" "ens23" "enp2s1" "enp2s2" "enp2s3") # Customize this list as needed

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

# System Type Section
echo -e "${PURPLE}${BOLD}System Type${NC}: ${PURPLE}Debian Router${NC}"
echo ""

# Update Check Section
updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
if [ "$updates" -gt 0 ]; then
    echo -e "${RED}${BOLD}Updates available: $updates package(s). Run 'apt update'${NC}"
    echo ""
fi

# System Information Group
echo -e "${PURPLE}${BOLD}System Information${NC}"
echo "======================"
if command -v lsb_release &> /dev/null; then
  distro=$(lsb_release -ds)
else
  distro=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d \")
fi
kernel=$(uname -r)

echo -e "${PURPLE}$(pad "Distribution")${NC} $distro"
echo -e "${PURPLE}$(pad "Kernel")${NC} $kernel"

uptime_info=$(uptime -p | sed 's/up //')
load=$(cat /proc/loadavg)
load_1=$(echo $load | cut -d " " -f1)
load_5=$(echo $load | cut -d " " -f2)
load_15=$(echo $load | cut -d " " -f3)
processes=$(ps -e | wc -l)

echo -e "${PURPLE}$(pad "Uptime")${NC} $uptime_info"
echo -e "${PURPLE}$(pad "Load Averages (1m, 5m, 15m)")${NC} $load_1, $load_5, $load_15"
echo -e "${PURPLE}$(pad "Processes")${NC} $processes"
echo ""

# CPU and Memory Group
echo -e "${PURPLE}${BOLD}CPU and Memory Usage${NC}"
echo "======================"
cpu_info=$(grep -m 1 'model name' /proc/cpuinfo | cut -d ':' -f 2 | xargs)
mem_total=$(free -h | grep Mem: | awk '{print $2}' | sed 's/Gi/G/')
mem_used=$(free -h | grep Mem: | awk '{print $3}' | sed 's/Gi/G/')
mem_free=$(free -h | grep Mem: | awk '{print $4}' | sed 's/Gi/G/')

echo -e "${PURPLE}$(pad "CPU")${NC} $cpu_info"
echo -e "${PURPLE}$(pad "Memory Usage")${NC} $mem_used used / $mem_total total"
echo -e "${PURPLE}$(pad "Memory Available")${NC} $mem_free"
disk_usage=$(df -h --total | grep total | awk '{print $3 " used / " $2 " total (" $5 " used)"}')
echo -e "${PURPLE}$(pad "Disk Usage")${NC} $disk_usage"
echo ""

# BIRD Routing Daemon Section
if command -v birdc &> /dev/null; then
  echo -e "${PURPLE}${BOLD}BIRD Routing Daemon${NC}"
  echo "======================"
  bird_status=$(systemctl is-active bird)
  bird_protocols_v4=$(birdc show protocols all | grep "v4" | grep -c "  up")
  bird_protocols_v6=$(birdc show protocols all | grep "v6" | grep -c "  up")
  bird_protocols_down=$(birdc show protocols | grep start | awk '{print $1}' | xargs)
  bird_memory=$(birdc show memory | awk '/Total:/ {print $2 " " $3}')

  echo -e "${PURPLE}$(pad "BIRD Status")${NC} $bird_status"
  echo -e "${PURPLE}$(pad "Active BIRD IPv4 Protocols")${NC} $bird_protocols_v4"
  echo -e "${PURPLE}$(pad "Active BIRD IPv6 Protocols")${NC} $bird_protocols_v6"
  
  if [ ! -z "$bird_protocols_down" ]; then
    echo -e "${PURPLE}$(pad "Protocols Down")${NC} $bird_protocols_down"
  fi

  echo -e "${PURPLE}$(pad "BIRD Memory Usage")${NC} $bird_memory"
  echo ""
fi
gre_tunnels=$(ip -d link show | grep -c gre)
echo -e "${PURPLE}$(pad "GRE Tunnels")${NC} $gre_tunnels"
echo ""

# Interface Statistics Section
echo -e "${PURPLE}${BOLD}Interface Statistics${NC}"
echo "========================"
for iface in "${INTERFACES[@]}"; do
    echo -e "${PURPLE}$iface:${NC} $(interface_statistics $iface)"
    echo ""  # Add a new line after each interface's statistics
done
