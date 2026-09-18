#!/usr/bin/env bash
# WiFi 菜单：选网络 → 有密码就弹密码框 → 连接
set -euo pipefail

nmcli device wifi rescan >/dev/null 2>&1 &
sleep 1.5

# 读取网络列表：SSID:SIGNAL:SECURITY（按信号强度排序）
mapfile -t lines < <(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null)

# 去重（同名只留信号最强的那个）
menu=""
declare -A seen=()
for line in "${lines[@]}"; do
    IFS=: read -r ssid sig sec <<< "$line"
    [ -z "$ssid" ] && continue
    [ -n "${seen[$ssid]:-}" ] && continue
    seen["$ssid"]=1
    menu+="$ssid ($sig%)\n"
done
menu+="🔒 连接隐藏网络\n刷新列表\n打开 WiFi\n关闭 WiFi"

choice="$(printf '%b\n' "$menu" | fuzzel --dmenu --prompt '󰤨 WiFi ')"
[ -z "$choice" ] && exit 0

case "$choice" in
    "刷新列表") exec "$0" ;;
    "打开 WiFi") nmcli radio wifi on; exit 0 ;;
    "关闭 WiFi") nmcli radio wifi off; exit 0 ;;
esac

# 隐藏网络：手动输入 SSID + 密码
if [ "$choice" = "🔒 连接隐藏网络" ]; then
    ssid="$(fuzzel --dmenu --prompt '网络名 (SSID) ')"
    [ -z "$ssid" ] && exit 0
    pass="$(fuzzel --dmenu --password --prompt "密码：$ssid ")"
    [ -z "$pass" ] && exit 0
    nmcli device wifi connect "$ssid" password "$pass"
    exit $?
fi

ssid="${choice%% (*}"

# 已经保存过密码的连接：直接连
if nmcli -t -f NAME connection show 2>/dev/null | grep -qxF "$ssid"; then
    nmcli connection up "$ssid"
    exit $?
fi

# 查这个网络是否需要密码
sec=""
for line in "${lines[@]}"; do
    IFS=: read -r s _ se <<< "$line"
    if [ "$s" = "$ssid" ]; then sec="$se"; break; fi
done

if [ -n "$sec" ]; then
    # 加密网络：弹密码框
    pass="$(fuzzel --dmenu --password --prompt "密码：$ssid ")"
    [ -z "$pass" ] && exit 0
    nmcli device wifi connect "$ssid" password "$pass"
else
    # 开放网络：直接连
    nmcli device wifi connect "$ssid"
fi
