#!/bin/bash

CURRENT_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')
STATE_FILE="/tmp/sway-floating-${CURRENT_WS//\//_}"

enable() {
    swaymsg "for_window [workspace=\"$CURRENT_WS\"] floating enable"
    swaymsg "[workspace=\"$CURRENT_WS\"] floating enable"
    touch "$STATE_FILE"
    notify-send "Floating enabled for workspace: $CURRENT_WS"
}

disable() {
    swaymsg "for_window [workspace=\"$CURRENT_WS\"] floating disable"
    swaymsg "[workspace=\"$CURRENT_WS\"] floating disable"
    swaymsg reload
    rm -f "$STATE_FILE"
    notify-send "Floating disabled for workspace: $CURRENT_WS"
}

case "$1" in
    "enable")
        enable
        ;;
    "disable")
        disable
        ;;
    "toggle")
        if [ -f "$STATE_FILE" ]; then
            disable
        else
            enable
        fi
        ;;
    *)
        echo "Usage: $0 {enable|disable|toggle}"
        exit 1
        ;;
esac
