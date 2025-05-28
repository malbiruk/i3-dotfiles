#!/bin/bash
choice=$(echo -e " Lock\n󰗽 Logout\n󰒲 Suspend\n󰜉 Reboot\n⏻ Shutdown" | wofi -d)

# Strip the icon part
action=$(echo "$choice" | sed 's/^[^ ]* //')

case "$action" in
    "Lock")
        swaylock -i /home/klim/Pictures/Wallpapers/noise_wp/dark_glitch_wallpaper.png -kl
        ;;
    "Logout")
        swaymsg exit
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
esac
