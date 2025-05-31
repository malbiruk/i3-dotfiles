#!/bin/bash

CURRENT_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')

case "$1" in
    "enable")
        swaymsg "for_window [workspace=\"$CURRENT_WS\"] floating enable"
        swaymsg "[workspace=__focused__] floating enable"
        echo "Floating enabled for workspace: $CURRENT_WS"
        ;;
    "disable")
        swaymsg "for_window [workspace=\"$CURRENT_WS\"] floating disable"
        swaymsg "[workspace=__focused__] floating disable"
        echo "Floating disabled for workspace: $CURRENT_WS"
        ;;
    *)
        echo "Usage: $0 {enable|disable}"
        exit 1
        ;;
esac
