#!/bin/bash
#
# a simple dmenu session script 
#
###

DMENU='dmenu -i -b -fn 'Hack-6' -nb '#0f0f0f' -nf '#888a85' -sb '#0f0f0f' -sf '#ffffff''
choice=$(echo -e "suspend\nlogout\nrestart\nshutdown" | $DMENU)

case "$choice" in
  logout) i3-msg exit & ;;
  shutdown) systemctl poweroff & ;;
  restart) systemctl reboot & ;;
  suspend) systemctl suspend & ;;
esac
