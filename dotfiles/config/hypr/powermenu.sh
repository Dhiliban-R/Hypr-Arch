#!/bin/bash

entries="   L
   S
   R
   P"

selected=$(echo -e "$entries" | wofi --dmenu --cache-file /dev/null | awk '{print $1}')

case $selected in
  )
    loginctl terminate-user $USER
    ;;
  )
    systemctl suspend
    ;;
  )
    systemctl reboot
    ;;
  )
    systemctl poweroff
    ;;
esac
