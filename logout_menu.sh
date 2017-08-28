#!/bin/bash

res=$(rofi -i -p "quit:" -dmenu < ~/.config/i3/logout_menu)

if [ $res = "logout" ]; then
    i3-msg exit
fi
if [ $res = "suspend" ]; then
    systemctl suspend
fi
if [ $res = "restart" ]; then
    systemctl reboot
fi
if [ $res = "shutdown" ]; then
    systemctl poweroff
fi
exit 0
