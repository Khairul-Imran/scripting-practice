#!/bin/bash

echo "Hello World"

echo "Welcome to Khairul's system monitoring dashboard!"

echo "We will be monitoring the CPU, Memory, Disk and Network usage of the system."


# Functions
# Function to monitor the CPU usage (TODO: Finish this function)
get_cpu_info() {
    echo "CPU Usage:"

    # Get CPU usage using top
    cpu_line=$(top -l 1 -n 0 | grep "CPU usage")

    # Exract user, system, and idle percentages
    user_percent=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
    system_percent=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')
    idle_percent=$(echo "$cpu_line" | awk '{print $7}' | sed 's/%//')

    # Calculate total usage
    total_used=$(echo "scale=1; $user_percent + $system_percent" | bc) # What does scale, and bc do?

    # Get CPU details (cores/threads)
    cpu_brand=$(sysctl -n machdep.cpu.brand_string)
    cpu_cores=$(sysctl -n hw.physicalcpu)
    cpu_threads=$(sysctl -n hw.logicalcpu)

    # Output
    echo " Model: $cpu_brand"
    echo " Cores: $cpu_cores physical, $cpu_threads logical"
    echo " User: ${user_percent}%"
    echo " System: ${system_percent}%"
    echo " Idle: ${idle_percent}%"
    echo " Total Usage: ${total_used}%"
    echo " -------------------------------------------"
}

# Function to monitor the Memory usage
get_memory_info() {
    # Get total physical memory in bytes
    total_mem=$(sysctl -n hw.memsize)

    # Convert to GB
    total_mem_gb=$(echo "scale=2; $total_mem / 1024^3" | bc)

    # Get memory statistics using vm_stat
    vm_stat_output=$(vm_stat)

    # Extract pages free and convert to human readable format
    pages_free=$(echo "$vm_state_output" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    page_size=$(sysctl -n hw.pagesize)
    free_mem=$(echo "scale=2; $pages_free * $page_size / 1024^3" | bc)

    # Calculate used memory
    used_mem=$(echo "scale=2; $total_mem_gb - $free_mem" | bc)

    # Calculate usage percentage
    usage_percentage=$(echo "scale=2; $used_mem / $total_mem_gb * 100" | bc)

    # Output
    echo "Memory Usage:"
    echo "  Total: ${total_mem_gb}GB"
    echo "  Used: ${used_mem}GB (${usage_percent}%)"
    echo "  Free: ${free_mem}GB"
    echo " -------------------------------------------"
}

# Function to monitor the Disk usage
get_disk_info() {
    echo "Disk Usage:"

    # Get disk usage for all mounted filesystems, filtering out non-standard ones
    df -h | grep -v "devfs\|map" | awk 'NR>1 {printf "  %s: %s used of %s (%s)\n", $9, $3, $2, $5}'
    echo " -------------------------------------------"
}

# Function to monitor the Network usage
get_network_info() {
    echo "Network Usage:"

    # Get list of active network interfaces (excluding loopback and inactive)
    interfaces=$(ifconfig | grep -E 'en[0-9]:' | cut -d: -f1)

    # For each interface, get the stats
    for interface in $interfaces; do
        echo "  Interface: $interface"

        # Get incoming/outgoing bytes
        in_bytes=$(netstat -ib | grep -E "$interface" | head -1 | awk '{print $7}')
        out_bytes=$(netstat -ib | grep -E "$interface" | head -1 | awk '{print $10}')

        # Convert to MB for readability
        in_mb=$(echo "scale=2; $in_bytes / 1024^2" | bc)
        out_mb=$(echo "scale=2; $out_bytes / 1024^2" | bc)

        # Get interface status (up/down) and IP
        status=$(ifconfig $interface | grep "status" | awk '{print $2}')
        ip=$(ifconfig $interface | grep "inet " | awk '{print $2}')

        echo "    Status: $status"
        if [ ! -z "$ip" ]; then
            echo "    IP: $ip"
        fi
        echo "    Total Received: ${in_mb}MB"
        echo "    Total Sent: ${out_mb}MB"

    done
    echo " -------------------------------------------"
}

get_cpu_info
echo ""
get_memory_info
echo ""
get_disk_info
echo ""
get_network_info

# TODO:
# Determine the layout of the dashboard
# To determine the refresh rate of the dashboard
# Allow user to generate the results to a .txt file
