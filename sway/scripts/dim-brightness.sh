#!/bin/sh

BRIGHTNESS_FILE="/tmp/last_brightness"

case "$1" in
  dim)
    # Save current brightness
    light -G > "$BRIGHTNESS_FILE"
    # Set to 10%
    light -S 10
    ;;
  restore)
    # Restore previous brightness if file exists
    if [ -f "$BRIGHTNESS_FILE" ]; then
      light -S "$(cat "$BRIGHTNESS_FILE")"
      rm "$BRIGHTNESS_FILE"
    fi
    ;;
esac
