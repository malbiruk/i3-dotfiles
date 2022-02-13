#!/bin/bash
xset -q|grep LED| awk '{ if (substr ($10,5,1) == 1) print "ru"; else print "en";}'
case $BLOCK_BUTTON in
  1) xkb-switch -n;;
esac
