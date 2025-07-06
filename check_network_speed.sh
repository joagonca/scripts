#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <network_interface>"
    echo "Example: $0 enp0s3"
    exit 1
fi

INTERFACE="$1"
SPEED_FILE="/sys/class/net/${INTERFACE}/speed"

if [ ! -f "$SPEED_FILE" ]; then
    echo "Error: Interface $INTERFACE not found or speed file does not exist"
    exit 1
fi

CURRENT_SPEED=$(cat "$SPEED_FILE" 2>/dev/null)

if [ -z "$CURRENT_SPEED" ] || [ "$CURRENT_SPEED" -eq -1 ]; then
    echo "Error: Unable to read speed for interface $INTERFACE (interface may be down)"
    exit 1
fi

echo "Current speed for $INTERFACE: ${CURRENT_SPEED} Mbps"

if [ "$CURRENT_SPEED" -lt 1000 ]; then
    echo "Speed is below 1000 Mbps. Resetting interface..."
    
    sudo ip link set "$INTERFACE" down
    if [ $? -ne 0 ]; then
        echo "Error: Failed to bring interface down"
        exit 1
    fi
    
    echo "Interface brought down. Waiting 5 seconds..."
    sleep 5
    
    sudo ip link set "$INTERFACE" up
    if [ $? -ne 0 ]; then
        echo "Error: Failed to bring interface up"
        exit 1
    fi
    
    echo "Interface brought back up. Requesting DHCP lease..."
    
    # Request new DHCP lease
    sudo dhclient -r "$INTERFACE" 2>/dev/null  # Release existing lease
    sudo dhclient "$INTERFACE"                  # Request new lease
    
    if [ $? -eq 0 ]; then
        echo "DHCP lease renewed successfully"
    else
        echo "Warning: DHCP renewal may have failed"
    fi
else
    echo "Speed is 1000 Mbps or higher. No action needed."
fi