#!/usr/bin/env bash
time=`date "+%H"`

if [[ $time > 5 ]] || [[ $time < 20 ]]; then
  /home/klim/.config/i3/gtk-switch.py --apply tl
else
  /home/klim/.config/i3/gtk-switch.py --apply td
fi
