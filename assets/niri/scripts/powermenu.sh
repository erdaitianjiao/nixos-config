#!/usr/bin/env bash
# 电源菜单 — fuzzel dmenu 版

options="󰌾  Lock
󰍃  Logout
󰜉  Reboot
󰐥  Shutdown"

chosen=$(printf '%s\n' "$options" | fuzzel --dmenu --prompt "⏻  Power ")

case "$chosen" in
    *Lock)     swaylock ;;
    *Logout)   niri msg action quit ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
