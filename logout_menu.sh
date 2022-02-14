#!/bin/bash

res=$(rofi -theme-str 'entry { placeholder: ""; } inputbar { children: [prompt, textbox-prompt-colon, entry];}' -i -p "quit" -dmenu < ~/.config/i3/logout_menu)

if [ $res = "lock screen" ]; then
    slock
fi
i
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
