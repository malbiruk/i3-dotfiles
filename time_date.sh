#!/bin/bash

time=`date '+%H:%M'`
date=`date '+%a, %d %b'`
case $BLOCK_BUTTON in
    1) echo "$date " ;;
    *) echo "$time" ;;
esac

