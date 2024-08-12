#!/bin/bash

# Define the interfaces you want to display
INTERFACES=("ens18" "ens19" "ens20") # Customize this list as needed

# Define colors
DARK_PURPLE='\033[38;5;93m'
LIGHT_PURPLE='\033[38;5;135m'
NC='\033[0m' # No Color

pad() {
  local text="$1"
  local padding=25
  local total_length=$((padding - ${#text}))
  printf "%s" "$text"
  printf "${NC}%0.s." $(seq 1 $total_length)
  printf "${NC}:"
}

color_gradient_art() {
  local color1="$1"
  local color2="$2"
  local color3="$3"
  local art="$4"

  local color_list=("$color1" "$color2" "$color3")
  local color_count=${#color_list[@]}
  
  while IFS= read -r line; do
    local line_length=${#line}
    local color_index=0

    for ((i=0; i<line_length; i++)); do
      color_index=$((i % color_count))
      
      printf "${color_list[$color_index]}%s" "${line:$i:1}"
    done
    printf "${NC}\n"
  done <<< "$art"
}

# ASCII Art
ascii_art=$(cat <<EOF
  _    ___     ________ _    _  ____   _____ _______ 
 | |  | \ \   / /  ____| |  | |/ __ \ / ____|__   __|
 | |__| |\ \_/ /| |__  | |__| | |  | | (___    | |   
 |  __  | \   / |  __| |  __  | |  | |\___ \   | |   
 | |  | |  | |  | |____| |  | | |__| |____) |  | |   
 |_|  |_|  |_|  |______|_|  |_|\____/|_____/   |_|                                                                                                            
EOF
)

color_gradient_art "$DARK_PURPLE" "$LIGHT_PURPLE" "$DARK_PURPLE" "$ascii_art"

echo ""
echo ""

# System Identification
if [ -f /etc/pve/.version ]; then
  echo -e "${NC}System Type: ${DARK_PURPLE}Proxmox Node${NC}"
elif command -v birdc &> /dev/null; then
  echo -e "${NC}System Type: ${DARK_PURPLE}Debian Router with BIRD${NC}"
else
  echo -e "${NC}System Type: ${DARK_PURPLE}Debian-based Machine${NC}"
fi
echo ""

# System Information
distro=$(lsb_release -ds || cat /etc/*release | grep ^NAME | head -n 1 | cut -d= -f2 | tr -d \")
kernel=$(uname -r)

echo -e "System Info:"
echo -e "${DARK_PURPLE}$(pad "Distribution")${NC} $distro"
echo -e "${DARK_PURPLE}$(pad "Kernel")${NC} $kernel"
echo ""

# Uptime, Load, Processes
uptime_info=$(uptime -p)
load=$(uptime | awk -F'load average:' '{ print $2 }' | xargs)
load_1=$(echo $load | cut -d, -f1)
load_5=$(echo $load | cut -d, -f2)
load_15=$(echo $load | cut -d, -f3)
processes=$(ps -e | wc -l)

echo -e "${DARK_PURPLE}$(pad "Uptime")${NC} $uptime_info"
echo -e "${DARK_PURPLE}$(pad "Load (1m)")${NC} $load_1"
echo -e "${DARK_PURPLE}$(pad "Load (5m)")${NC} $load_5"
echo -e "${DARK_PURPLE}$(pad "Load (15m)")${NC} $load_15"
echo -e "${DARK_PURPLE}$(pad "Processes")${NC} $processes"
echo ""

# CPU and Memory Usage
cpu_info=$(grep -m 1 'model name' /proc/cpuinfo | cut -d ':' -f 2 | xargs)
mem_total=$(free -h | grep Mem: | awk '{print $2}' | sed 's/Gi/G/')
mem_used=$(free -h | grep Mem: | awk '{print $3}' | sed 's/Gi/G/')
mem_free=$(free -h | grep Mem: | awk '{print $4}' | sed 's/Gi/G/')

echo -e "${DARK_PURPLE}$(pad "CPU")${NC} $cpu_info"
echo -e "${DARK_PURPLE}$(pad "Mem Used")${NC} $mem_used"
echo -e "${DARK_PURPLE}$(pad "Mem Available")${NC} $mem_free"
echo -e "${DARK_PURPLE}$(pad "Mem Total")${NC} $mem_total"
echo ""

# Disk Usage
disk_usage=$(df -h --total | grep total | awk '{print $3 " used / " $2 " total (" $5 " used)"}')

echo -e "${DARK_PURPLE}$(pad "Disk Usage")${NC} $disk_usage"
echo ""

# Proxmox Information
if [ -f /etc/pve/.version ]; then
  proxmox_version=$(pveversion)
  echo -e "${DARK_PURPLE}$(pad "Proxmox Version")${NC} $proxmox_version"
  
  # Display running VMs
  echo -e "${NC}Running VMs:"
  qm list | awk 'NR>1 {printf "${DARK_PURPLE}%s${NC} (Status: %s)\n", $2, $3}'
  echo ""
  
  # Display storage status
  echo -e "${NC}Storage Usage:"
  pvesm status | awk 'NR>1 {printf "${DARK_PURPLE}%s${NC}: %s used / %s total (%s used)\n", $1, $3, $2, $5}'
  echo ""
fi

# BIRD Routing Daemon Information
if command -v birdc &> /dev/null; then
  bird_status=$(systemctl is-active bird)
  bird_protocols_up=$(birdc show protocols | grep up | wc -l)
  bird_protocols_down=$(birdc show protocols | grep down | awk '{print $1}' | xargs)
  
  ipv4_routes=$(ip -4 route | wc -l)
  ipv6_routes=$(ip -6 route | wc -l)
  
  bird_memory=$(birdc show memory | awk '/Total:/ {print $2 " " $3}')

  echo -e "${DARK_PURPLE}$(pad "BIRD Status")${NC} $bird_status"
  echo -e "${DARK_PURPLE}$(pad "Active BIRD Protocols")${NC} $bird_protocols_up"
  
  if [ ! -z "$bird_protocols_down" ]; then
    echo -e "${DARK_PURPLE}$(pad "Protocols Down")${NC} $bird_protocols_down"
  fi

  echo -e "${DARK_PURPLE}$(pad "Total Routes (IPv4)")${NC} $ipv4_routes"
  echo -e "${DARK_PURPLE}$(pad "Total Routes (IPv6)")${NC} $ipv6_routes"
  echo -e "${DARK_PURPLE}$(pad "BIRD Memory Usage")${NC} $bird_memory"
  echo ""
fi

# Network Interface Information
echo -e "${NC}Interfaces:"
for iface in "${INTERFACES[@]}"; do
    echo -e "${DARK_PURPLE}$iface:${NC}"
    ip addr show "$iface" | grep -E "inet |inet6 " | awk '{print $2}' | while read -r ip; do
        echo -e "  IP.......................: $ip"
    done
    echo ""
done

# Tunnels
gre_tunnels=$(ip -d link show | grep -c gre)
echo -e "${DARK_PURPLE}$(pad "Tunnels")${NC} ${gre_tunnels}"
