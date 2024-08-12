#!/bin/bash

# Define the interfaces you want to display
INTERFACES=("ens18" "ens19" "ens20") # Customize this list as needed

# Define colors
PURPLE='\033[38;5;135m'
NC='\033[0m' # No Color

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

# ASCII Art
ascii_art=$(cat <<EOF

   ▄█    █▄    ▄██   ▄      ▄████████    ▄█    █▄     ▄██████▄     ▄████████     ███
  ███    ███   ███   ██▄   ███    ███   ███    ███   ███    ███   ███    ███ ▀█████████▄
  ███    ███   ███▄▄▄███   ███    █▀    ███    ███   ███    ███   ███    █▀     ▀███▀▀██
 ▄███▄▄▄▄███▄▄ ▀▀▀▀▀▀███  ▄███▄▄▄      ▄███▄▄▄▄███▄▄ ███    ███   ███            ███   ▀
▀▀███▀▀▀▀███▀  ▄██   ███ ▀▀███▀▀▀     ▀▀███▀▀▀▀███▀  ███    ███ ▀███████████     ███
  ███    ███   ███   ███   ███    █▄    ███    ███   ███    ███          ███     ███
  ███    ███   ███   ███   ███    ███   ███    ███   ███    ███    ▄█    ███     ███
  ███    █▀     ▀█████▀    ██████████   ███    █▀     ▀██████▀   ▄████████▀     ▄████▀
EOF
)

echo "$ascii_art" | lolcat

echo ""
echo ""

# System Identification
echo -e "${NC}System Type: ${PURPLE}Debian Router${NC}"
echo ""

# System Information
if command -v lsb_release &> /dev/null; then
  distro=$(lsb_release -ds)
else
  distro=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d \")
fi
kernel=$(uname -r)

echo -e "System Info:"
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

# BIRD Routing Daemon Information
if command -v birdc &> /dev/null; then
  bird_status=$(systemctl is-active bird)
  
  bird_protocols_v4=$(birdc show protocols all | grep "v4" | grep -c "  up")
  bird_protocols_v6=$(birdc show protocols all | grep "v6" | grep -c "  up")
  bird_protocols_down=$(birdc show protocols | grep down | awk '{print $1}' | xargs)

  ipv4_routes=$(ip -4 route | wc -l)
  ipv6_routes=$(ip -6 route | wc -l)

  bird_memory=$(birdc show memory | awk '/Total:/ {print $2 " " $3}')

  echo -e "${PURPLE}$(pad "BIRD Status")${NC} $bird_status"
  echo -e "${PURPLE}$(pad "Active BIRD IPv4 Protocols")${NC} $bird_protocols_v4"
  echo -e "${PURPLE}$(pad "Active BIRD IPv6 Protocols")${NC} $bird_protocols_v6"

  if [ ! -z "$bird_protocols_down" ]; then
    echo -e "${PURPLE}$(pad "Protocols Down")${NC} $bird_protocols_down"
  fi

  echo -e "${PURPLE}$(pad "Total Routes (IPv4)")${NC} $ipv4_routes"
  echo -e "${PURPLE}$(pad "Total Routes (IPv6)")${NC} $ipv6_routes"
  echo -e "${PURPLE}$(pad "BIRD Memory Usage")${NC} $bird_memory"
  echo ""
fi

# GRE Tunnel Count
gre_tunnels=$(ip -d link show | grep -c gre)
echo -e "${PURPLE}$(pad "Tunnels")${NC} $gre_tunnels"
echo ""

# Interface statistics only
echo -e "${NC}Interface Statistics:"
for iface in "${INTERFACES[@]}"; do
    echo -e "${PURPLE}$iface:${NC} $(interface_statistics $iface)"
    echo ""  # Add a new line after each interface's statistics
done
