#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# MOTD directory
MOTD_DIR="/etc/update-motd.d/"

# Function to clear current MOTD
clear_motd() {
    echo "Clearing current MOTD..."
    rm -f ${MOTD_DIR}*
}

# Function to apply a specified MOTD
apply_motd() {
    local flag=$1
    local motd_file="${SCRIPT_DIR}/${flag}-motd.sh"

    if [ -f "$motd_file" ]; then
        echo "Applying ${flag} MOTD..."
        clear_motd
        cp "$motd_file" "${MOTD_DIR}99-custom-motd"
        chmod +x "${MOTD_DIR}99-custom-motd"
    else
        echo "MOTD script ${flag}-motd.sh not found in ${SCRIPT_DIR}."
        exit 1
    fi
}

# Check if a flag is provided and apply the corresponding MOTD
if [ $# -eq 1 ]; then
    flag="${1#-}" # Remove the leading dash from the flag
    apply_motd "$flag"
else
    echo "Usage: apply-motd.sh -flag (e.g., -rtr for rtr-motd.sh or -pve for pve-motd.sh)"
    exit 1
fi
