#!/bin/bash

# Define the interfaces you want to display
INTERFACES=("enp1s0f0" "enp1s0f1") # Customize this list as needed

# Define colors
RAINBOW_GRADIENT=('\033[38;5;196m' '\033[38;5;208m' '\033[38;5;220m' '\033[38;5;82m' '\033[38;5;39m' '\033[38;5;21m' '\033[38;5;201m')
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

gradient_rainbow_ascii_art() {
  local art="$1"
  local color_index=0
  local total_colors=${#RAINBOW_GRADIENT[@]}

  while IFS= read -r line; do
    local line_length=${#line}

    for ((i=0; i<line_length; i++)); do
      printf "${RAINBOW_GRADIENT[$((color_index % total_colors))]}%s" "${line:$i:1}"
      color_index=$((color_index + 1))
    done
    printf "${NC}\n"
  done <<< "$art"
}

# Compact ASCII Art without unnecessary spacing
ascii_art=$(cat <<EOF
  _    ___     ________ _    _  ____   _____ _______ 
 | |  | \ \   / /  ____| |  | |/ __ \ / ____|__   __|
 | |__| |\ \_/ /| |__  | |__| | |  | | (___    | |   
 |  __  | \   / |  __| |  __  | |  | |\___ \   | |   
 | |  | |  | |  | |____| |  | | |__| |____) |  | |   
 |_|  |_|  |_|  |______|_|  |_|\____/|_____/   |_|   
EOF
)

gradient_rainbow_ascii_art "$ascii_art"

echo ""
echo ""

# System Identification
echo -e "${NC}System Type: ${PURPLE}Proxmox Node${NC}"
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

# Interface statistics
echo -e "${NC}Interface Statistics:"
for iface in "${INTERFACES[@]}"; do
    echo -e "${PURPLE}$iface:${NC} $(interface_statistics $iface)\n"
done
echo ""
