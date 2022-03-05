#!/usr/bin/env bash
ip=`curl ifconfig.me`

if [[ $ip != "46.242.8.214" ]]
then
  echo "vpn_on"
else
  echo "vpn_off"
fi
