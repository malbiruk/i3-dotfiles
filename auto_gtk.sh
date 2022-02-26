#!/usr/bin/env bash
time=`date "+%H"`
echo $time

if [[ $time < 8 || $time > 20 ]]; then
  /home/klim/.config/i3/gtk-switch.py --apply td
else
  /home/klim/.config/i3/gtk-switch.py --apply tl
fi
