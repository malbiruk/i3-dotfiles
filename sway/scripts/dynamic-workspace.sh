#!/bin/bash

direction=$1
move_container=${2:-false}  # second argument for moving containers

current=$(swaymsg -t get_workspaces | jq '.[] | select(.focused) | .num')

if [ "$direction" = "next" ]; then
    target=$((current + 1))
elif [ "$direction" = "prev" ]; then
    target=$((current - 1))
    [ $target -lt 0 ] && target=0
fi

# Move container if requested
if [ "$move_container" = "true" ]; then
    swaymsg move container to workspace number $target
fi

# Always switch to the target workspace
swaymsg workspace number $target
