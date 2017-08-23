#!/bin/bash
time=`date '+%H:%M'`
date=`date '+%d %b, %a'`
case $BLOCK_BUTTON in
    1) echo "$date " ;;
    *) echo "$time" ;;
esac
