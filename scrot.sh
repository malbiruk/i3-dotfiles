#!/usr/bin/bash

scrot -a $(slop -f '%x,%y,%w,%h') '/tmp/%F_%T_$wx$h.png' -e 'xclip -select    ion clipboard -target image/png -i $f'
