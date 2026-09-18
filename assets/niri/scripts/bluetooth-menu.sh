#!/usr/bin/env bash
# 蓝牙菜单：开关蓝牙 + 连接/断开已配对设备
set -euo pipefail

if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    power="关闭蓝牙"
else
    power="打开蓝牙"
fi

mapfile -t devs < <(bluetoothctl devices 2>/dev/null | sed 's/^Device //')

menu="$power"
for d in "${devs[@]}"; do
    menu+="
${d#* }"
done

choice="$(printf '%b\n' "$menu" | fuzzel --dmenu --prompt "󰂯 Bluetooth ")"
[ -z "$choice" ] && exit 0

case "$choice" in
    关闭蓝牙) bluetoothctl power off ;;
    打开蓝牙) bluetoothctl power on ;;
    *)
        for d in "${devs[@]}"; do
            name="${d#* }"
            if [ "$choice" = "$name" ]; then
                mac="${d%% *}"
                if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
                    bluetoothctl disconnect "$mac"
                else
                    bluetoothctl connect "$mac"
                fi
                break
            fi
        done
        ;;
esac
