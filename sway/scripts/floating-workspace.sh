#!/bin/bash

CURRENT_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')

case "$1" in
    "enable")
        # Add a specific for_window rule for this workspace
        swaymsg "for_window [workspace=\"$CURRENT_WS\"] floating enable"
        # Enable floating for current windows
        swaymsg "[workspace=__focused__] floating enable"
        notify-send "Floating enabled for workspace: $CURRENT_WS"
        ;;
    "disable")
        # Try to counteract by adding a disable rule (this is hacky but might work)
        swaymsg "for_window [workspace=\"$CURRENT_WS\"] floating disable"
        # Disable floating for current windows
        swaymsg "[workspace=__focused__] floating disable"
	swaymsg reload
        notify-send "Floating disabled for workspace: $CURRENT_WS"
        ;;
    *)
        echo "Usage: $0 {enable|disable}"
        exit 1
        ;;
esac
