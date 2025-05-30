#!/bin/bash

# Configuration for notification thresholds
CPU_CRITICAL=90
MEMORY_CRITICAL=90
DISK_CRITICAL=90
BATTERY_LOW=15
BATTERY_CRITICAL=5

# Global state tracking to avoid spam notifications
LAST_CPU_ALERT=0
LAST_MEMORY_ALERT=0
LAST_DISK_ALERT=0
LAST_BATTERY_ALERT=0
LAST_BLUETOOTH_DISCONNECT=0

# Notification cooldown (seconds)
NOTIFICATION_COOLDOWN=300  # 5 minutes

# Directory for state files
STATE_DIR="/tmp/status_bar_notifications"
mkdir -p "$STATE_DIR"


get_window_title() {
    title=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true).name // empty' 2>/dev/null | head -1)

    # Check if title is just a number (workspace number) or empty
    if [ -n "$title" ] && ! [[ "$title" =~ ^[0-9]+$ ]]; then
        echo "󱂬 $title"
    fi
}

send_notification() {
    local urgency="$1"
    local title="$2"
    local message="$3"
    local icon="$4"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$message"
    fi
}

check_notification_cooldown() {
    local alert_type="$1"
    local state_file="$STATE_DIR/${alert_type}_last_alert"
    local current_time=$(date +%s)

    if [ -f "$state_file" ]; then
        local last_alert=$(cat "$state_file")
        local time_diff=$((current_time - last_alert))
        if [ $time_diff -lt $NOTIFICATION_COOLDOWN ]; then
            return 1  # Still in cooldown
        fi
    fi

    # Update the state file
    echo "$current_time" > "$state_file"
    return 0  # Can send notification
}

get_cpu_usage() {
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_int=$(printf "%.0f" "$cpu")

    # Check for critical CPU usage
    if [ "$cpu_int" -ge "$CPU_CRITICAL" ]; then
        if check_notification_cooldown "$LAST_CPU_ALERT"; then
            send_notification "critical" "High CPU Usage" "CPU usage is at ${cpu}%" "dialog-warning"
            LAST_CPU_ALERT=$(date +%s)
        fi
    fi

    echo "  ${cpu}%"
}

get_memory_usage() {
    # Get both percentage and absolute values
    mem_info=$(free -h | grep Mem)
    mem_percent=$(echo "$mem_info" | awk '{printf("%.0f", ($3/$2) * 100.0)}')
    mem_used=$(echo "$mem_info" | awk '{print $3}')
    mem_total=$(echo "$mem_info" | awk '{print $2}')

    # Check for critical memory usage
    if [ "$mem_percent" -ge "$MEMORY_CRITICAL" ]; then
        if check_notification_cooldown "$LAST_MEMORY_ALERT"; then
            send_notification "critical" "High Memory Usage" "Memory usage is at ${mem_percent}% (${mem_used}/${mem_total})" "dialog-warning"
            LAST_MEMORY_ALERT=$(date +%s)
        fi
    fi

    echo "  ${mem_percent}% (${mem_used})"  # nf-md-memory
}

get_disk_usage() {
    if [ -d "/home" ]; then
        disk_info=$(df -BG /home | awk 'NR==2')
        home_used=$(echo "$disk_info" | awk '{print $3}' | sed 's/G//')
        home_used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
        disk_percent="$home_used_percent"
        disk_location="/home"
        echo "  ${home_used}Gb (${home_used_percent}%)"
    else
        disk_info=$(df -BG / | awk 'NR==2')
        root_used=$(echo "$disk_info" | awk '{print $3}' | sed 's/G//')
        root_used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
        disk_percent="$root_used_percent"
        disk_location="/"
        echo "  ${root_used}Gb (${root_used_percent}%)"
    fi

    # Check for critical disk usage
    if [ "$disk_percent" -ge "$DISK_CRITICAL" ]; then
        if check_notification_cooldown "$LAST_DISK_ALERT"; then
            send_notification "critical" "Low Disk Space" "Disk usage for $disk_location is at ${disk_percent}%" "drive-harddisk"
            LAST_DISK_ALERT=$(date +%s)
        fi
    fi
}

get_network() {
    if command -v nmcli >/dev/null 2>&1; then
        # Get active WiFi connection - looking for 802-11-wireless type
        wifi_name=$(nmcli -t -f NAME,TYPE connection show --active | grep ":802-11-wireless$" | cut -d: -f1)

        if [ -n "$wifi_name" ]; then
            # Get WiFi info from the active connection (marked with *)
            wifi_line=$(nmcli dev wifi | grep "^\*")

            if [ -n "$wifi_line" ]; then
                # Extract SSID (should be the same as wifi_name)
                ssid="$wifi_name"

                # Extract signal strength (number followed by no space, before BARS)
                signal=$(echo "$wifi_line" | grep -oE '[0-9]{1,3}[ ]+[▂▄▆█_]{4}' | awk '{print $1}')

                # Choose WiFi icon based on signal strength
                if [ -n "$signal" ]; then
                    if [ "$signal" -ge 75 ]; then
                        wifi_icon="󰤨"  # nf-md-wifi_strength_4
                    elif [ "$signal" -ge 50 ]; then
                        wifi_icon="󰤥"  # nf-md-wifi_strength_3
                    elif [ "$signal" -ge 25 ]; then
                        wifi_icon="󰤢"  # nf-md-wifi_strength_2
                    else
                        wifi_icon="󰤟"  # nf-md-wifi_strength_1
                    fi
                    echo "${wifi_icon}  ${ssid} (${signal}%)"
                else
                    # Fallback if signal detection fails
                    echo "󰤯  ${ssid}"  # nf-md-wifi_strength_outline
                fi
            else
                echo "󰤯  ${wifi_name}"  # nf-md-wifi_strength_outline
            fi
        else
            # Check for ethernet connection
            eth_name=$(nmcli -t -f NAME,TYPE connection show --active | grep ":ethernet$" | cut -d: -f1)
            if [ -n "$eth_name" ]; then
                echo "󰈀  ${eth_name}"  # nf-md-ethernet (if you have it)
            else
                # No network connection - send notification
                send_notification "normal" "Network Disconnected" "No active network connection" "network-offline"
                echo "󰤭"  # nf-md-wifi_strength_off
            fi
        fi
    else
        echo "󰤭"  # nf-md-wifi_strength_off
    fi
}

get_bluetooth() {
    # Check if bluetooth service is available
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        return
    fi

    # Check if bluetooth adapter is powered on
    powered=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

    if [ "$powered" != "yes" ]; then
        echo "󰂲 (off)"  # nf-md-bluetooth_off
        return
    fi

    # Get connected devices
    connected_devices=$(bluetoothctl devices Connected 2>/dev/null)

    if [ -z "$connected_devices" ]; then
        # Bluetooth is on but no devices connected
        echo "󰂯 (on)"  # nf-md-bluetooth
    else
        # Count connected devices
        device_count=$(echo "$connected_devices" | wc -l)

        # Get first connected device name (truncated)
        first_device=$(echo "$connected_devices" | head -1 | sed 's/Device [0-9A-F:]\+ //')

        if [ ${#first_device} -gt 15 ]; then
            first_device="${first_device:0:15}..."
        fi

        if [ "$device_count" -eq 1 ]; then
            echo "󰂱 ${first_device} (1)"  # nf-md-bluetooth_connect with device count
        else
            echo "󰂱 ${first_device} (${device_count})"  # nf-md-bluetooth_connect with device count
        fi
    fi
}

get_volume() {
    # Try pipewire/pulseaudio first, then ALSA
    if command -v wpctl >/dev/null 2>&1; then
        vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
        muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")
    elif command -v pactl >/dev/null 2>&1; then
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -o "yes")
    else
        vol=$(amixer get Master | grep -oP '\d+%' | head -1 | tr -d '%')
        muted=$(amixer get Master | grep -o '\[off\]')
    fi

    if [ -n "$muted" ]; then
        echo "󰖁 Muted"  # nf-md-volume_off
    else
        # Choose volume icon based on level
        if [ "$vol" -gt 66 ]; then
            vol_icon="󰕾"  # nf-md-volume_high
        elif [ "$vol" -gt 33 ]; then
            vol_icon="󰖀"  # nf-md-volume_medium
        elif [ "$vol" -gt 0 ]; then
            vol_icon="󰕿"  # nf-md-volume_low
        else
            vol_icon="󰖁"  # nf-md-volume_off
        fi
        echo "${vol_icon} ${vol}%"
    fi
}

get_brightness() {
    # Try light first, then brightnessctl, then fallback to reading sysfs directly
    if command -v light >/dev/null 2>&1; then
        brightness=$(light -G 2>/dev/null | cut -d'.' -f1)
    elif command -v brightnessctl >/dev/null 2>&1; then
        brightness=$(brightnessctl get 2>/dev/null)
        max_brightness=$(brightnessctl max 2>/dev/null)
        if [ -n "$brightness" ] && [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ]; then
            brightness=$((brightness * 100 / max_brightness))
        else
            brightness=""
        fi
    else
        # Fallback to reading sysfs directly
        backlight_device=""
        for device in /sys/class/backlight/*; do
            if [ -d "$device" ]; then
                backlight_device="$device"
                break
            fi
        done

        if [ -n "$backlight_device" ] && [ -f "$backlight_device/brightness" ] && [ -f "$backlight_device/max_brightness" ]; then
            current=$(cat "$backlight_device/brightness" 2>/dev/null)
            max=$(cat "$backlight_device/max_brightness" 2>/dev/null)
            if [ -n "$current" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
                brightness=$((current * 100 / max))
            fi
        fi
    fi

    if [ -n "$brightness" ]; then
        # Choose brightness icon based on level
        if [ "$brightness" -gt 75 ]; then
            brightness_icon="󰃠"  # nf-md-brightness_7
        elif [ "$brightness" -gt 50 ]; then
            brightness_icon="󰃟"  # nf-md-brightness_6
        elif [ "$brightness" -gt 25 ]; then
            brightness_icon="󰃞"  # nf-md-brightness_5
        elif [ "$brightness" -gt 0 ]; then
            brightness_icon="󰃝"  # nf-md-brightness_4
        else
            brightness_icon="󰃚"  # nf-md-brightness_1
        fi
        echo "${brightness_icon} ${brightness}%"
    fi
}

get_battery() {
    local battery_capacity=""
    local battery_status=""

    # Try upower first (more reliable on some systems)
    if command -v upower >/dev/null 2>&1; then
        # Get battery device path
        battery_device=$(upower -e | grep 'BAT' | head -1)

        if [ -n "$battery_device" ]; then
            battery_info=$(upower -i "$battery_device" 2>/dev/null)

            if [ -n "$battery_info" ]; then
                # Extract percentage (like "58%")
                capacity=$(echo "$battery_info" | grep "percentage" | grep -oE "[0-9]+" | head -1)

                # Extract state (like "discharging", "charging", "fully-charged")
                status=$(echo "$battery_info" | grep "state:" | awk '{print $2}')

                # Extract time remaining
                time_remaining=""
                if [ "$status" = "discharging" ]; then
                    time_remaining=$(echo "$battery_info" | grep "time to empty:" | sed 's/.*time to empty:[[:space:]]*//' | sed 's/[[:space:]]*hours.*/h/' | sed 's/[[:space:]]*minutes.*/m/')
                elif [ "$status" = "charging" ]; then
                    time_remaining=$(echo "$battery_info" | grep "time to full:" | sed 's/.*time to full:[[:space:]]*//' | sed 's/[[:space:]]*hours.*/h/' | sed 's/[[:space:]]*minutes.*/m/')
                fi

                if [ -n "$capacity" ]; then
                    battery_capacity="$capacity"
                    battery_status="$status"

                    # Choose icon based on status and capacity
                    if [ "$status" = "charging" ]; then
                        icon="󰂄"  # nf-md-battery_charging
                    elif [ "$status" = "fully-charged" ]; then
                        icon="󰁹"  # nf-md-battery
                    elif [ "$capacity" -gt 75 ]; then
                        icon="󰂂"  # nf-md-battery_80
                    elif [ "$capacity" -gt 50 ]; then
                        icon="󰂀"  # nf-md-battery_60
                    elif [ "$capacity" -gt 25 ]; then
                        icon="󰁾"  # nf-md-battery_40
                    else
                        icon="󰁺"  # nf-md-battery_20
                    fi

                    # Add time remaining if available
                    if [ -n "$time_remaining" ] && [ "$time_remaining" != "" ]; then
                        echo "${icon} ${capacity}% (${time_remaining})"
                    else
                        echo "${icon} ${capacity}%"
                    fi
                fi
            fi
        fi
    else
        # Fallback to /sys method if upower fails
        battery_path=""
        for bat in /sys/class/power_supply/BAT*; do
            if [ -d "$bat" ]; then
                battery_path="$bat"
                break
            fi
        done

        if [ -n "$battery_path" ] && [ -f "$battery_path/capacity" ]; then
            capacity=$(cat "$battery_path/capacity" 2>/dev/null)
            status=$(cat "$battery_path/status" 2>/dev/null)

            if [ -n "$capacity" ]; then
                battery_capacity="$capacity"
                battery_status="$status"

                if [ "$status" = "Charging" ]; then
                    icon="󰂄"  # nf-md-battery_charging
                elif [ "$capacity" -gt 75 ]; then
                    icon="󰂂"  # nf-md-battery_80
                elif [ "$capacity" -gt 50 ]; then
                    icon="󰂀"  # nf-md-battery_60
                elif [ "$capacity" -gt 25 ]; then
                    icon="󰁾"  # nf-md-battery_40
                else
                    icon="󰁺"  # nf-md-battery_20
                fi

                echo "${icon} ${capacity}%"
            fi
        fi
    fi

    # Check for battery alerts
    if [ -n "$battery_capacity" ] && [ "$battery_status" != "charging" ] && [ "$battery_status" != "Charging" ] && [ "$battery_status" != "fully-charged" ]; then
        if [ "$battery_capacity" -le "$BATTERY_CRITICAL" ]; then
            if check_notification_cooldown "battery_critical"; then
                send_notification "critical" "Critical Battery Level" "Battery is at ${battery_capacity}%. Please charge immediately!" "battery-caution"
            fi
        elif [ "$battery_capacity" -le "$BATTERY_LOW" ]; then
            if check_notification_cooldown "battery_low"; then
                send_notification "normal" "Low Battery" "Battery is at ${battery_capacity}%. Consider charging soon." "battery-low"
            fi
        fi
    fi
}

get_keyboard_layout() {
    layout=$(swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -1 2>/dev/null)
    if [ -n "$layout" ]; then
        # Shorten common layout names
        case "$layout" in
            *"English"*) layout="EN" ;;
            *"Russian"*) layout="RU" ;;
            *"German"*) layout="DE" ;;
            *"French"*) layout="FR" ;;
            *) layout=$(echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]') ;;
        esac
        echo "󰌌 ${layout}"  # nf-md-keyboard
    fi
}

get_date_time() {
    date +'󰃭 %Y-%m-%d (%a) | 󰥔 %H:%M:%S'  # nf-md-calendar, nf-md-clock
}

# Cleanup function
cleanup() {
    rm -rf "$STATE_DIR"
    exit 0
}

# Set up cleanup on script exit
trap cleanup EXIT INT TERM

# Main loop
while true; do
    # Get window title (truncate if too long)
    window_title=$(get_window_title)
    if [ ${#window_title} -gt 90 ]; then
        window_title="${window_title:0:90}..."
    fi

    # Build status string
    status=""

    # Add window title if available
    [ -n "$window_title" ] && status="${status}${window_title} | "

    # Add system info
    status="${status}$(get_cpu_usage) | "
    status="${status}$(get_memory_usage) | "
    status="${status}$(get_disk_usage) | "
    status="${status}$(get_network) | "
    bluetooth=$(get_bluetooth)
    [ -n "$bluetooth" ] && status="${status}${bluetooth} | "
    status="${status}$(get_volume) | "

    # Add brightness if available
    brightness=$(get_brightness)
    [ -n "$brightness" ] && status="${status}${brightness} | "

    # Add battery if available
    battery=$(get_battery)
    [ -n "$battery" ] && status="${status}${battery} | "

    # Add keyboard layout
    layout=$(get_keyboard_layout)
    [ -n "$layout" ] && status="${status}${layout} | "

    # Add date/time
    status="${status}$(get_date_time)"

    echo "$status"
    sleep 1
done
