#!/bin/bash

entries="    L
    S
    R
    P"

selected=$(echo -e "$entries" | wofi --dmenu --cache-file /dev/null | awk '{print $1}')

case $selected in
  )
    loginctl terminate-user $USER
    ;;
  )
    swaylock -i "/home/dhili/Downloads/Pretty scenery wallpaper_files/Boruto.png" --indicator-radius 90 --indicator-thickness 15 # Start swaylock in the background
    systemctl suspend
    ;;
  )
    systemctl reboot
    ;;
  )
    systemctl poweroff
    ;;
esac
