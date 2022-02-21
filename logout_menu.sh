#!/bin/bash

res=$(rofi -theme-str 'entry { placeholder: ""; } inputbar { children: [prompt, textbox-prompt-colon, entry];}' -i -p "quit" -dmenu < ~/.config/i3/logout_menu)

if [ $res = "logout" ]; then
    i3-msg exit
fi
if [ $res = "suspend" ]; then
    slock & systemctl suspend & sudo zzz
fi
if [ $res = "restart" ]; then
    systemctl reboot & sudo reboot
fi
if [ $res = "shutdown" ]; then
    systemctl poweroff & sudo poweroff
fi
if [ $res = "hibernation" ]; then
    sudo ZZZ
fi
exit 0
