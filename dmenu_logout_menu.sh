#!/bin/bash
#
# a simple dmenu session script 
#
###

DMENU='dmenu -i -b -fn 'Hack-6' -nb '#030d10' -nf '#97a4ad' -sb '#030d10' -sf '#ffe4ce''
choice=$(echo -e "logout\nsuspend\nrestart\nshutdown" | $DMENU)

case "$choice" in
  logout) i3-msg exit & ;;
  shutdown) systemctl poweroff & ;;
  restart) systemctl reboot & ;;
  suspend) systemctl suspend & ;;
esac
