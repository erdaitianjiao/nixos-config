#!/usr/bin/env bash
# 蓝牙开关（点击蓝牙图标用）
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off
else
    bluetoothctl power on
fi
