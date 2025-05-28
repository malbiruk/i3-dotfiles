#!/bin/bash

get_window_title() {
    title=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true).name // empty' 2>/dev/null | head -1)

    # Check if title is just a number (workspace number) or empty
    if [ -n "$title" ] && ! [[ "$title" =~ ^[0-9]+$ ]]; then
        echo "󱂬 $title"
    fi
}

get_cpu_usage() {
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "  ${cpu}%"
}

get_memory_usage() {
    # Get both percentage and absolute values
    mem_info=$(free -h | grep Mem)
    mem_percent=$(echo "$mem_info" | awk '{printf("%.0f", ($3/$2) * 100.0)}')
    mem_used=$(echo "$mem_info" | awk '{print $3}')
    mem_total=$(echo "$mem_info" | awk '{print $2}')
    echo "  ${mem_percent}% (${mem_used})"  # nf-md-memory
}

get_disk_usage() {
    if [ -d "/home" ]; then
        disk_info=$(df -BG /home | awk 'NR==2')
        home_used=$(echo "$disk_info" | awk '{print $3}' | sed 's/G//')
        home_used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
        echo "  ${home_used}Gb (${home_used_percent}%)"
    else
        disk_info=$(df -BG / | awk 'NR==2')
        root_used=$(echo "$disk_info" | awk '{print $3}' | sed 's/G//')
        root_used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
        echo "  ${root_used}Gb (${root_used_percent}%)"
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
                echo "󰤭"  # nf-md-wifi_strength_off
            fi
        fi
    else
        echo "󰤭"  # nf-md-wifi_strength_off
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

get_battery() {
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
                    return
                fi
            fi
        fi
    fi

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

# Main loop
while true; do
    # Get window title (truncate if too long)
    window_title=$(get_window_title)
    if [ ${#window_title} -gt 100 ]; then
        window_title="${window_title:0:100}..."
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
    status="${status}$(get_volume) | "

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
