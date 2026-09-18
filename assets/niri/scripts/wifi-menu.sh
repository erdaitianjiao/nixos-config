#!/usr/bin/env bash
# WiFi 菜单：选网络 → 需要密码就弹小输入框 → 连接
set -euo pipefail

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a WiFi "$1" "${2:-}" || true; }

prompt_pass() {
    # --prompt-only：dmenu 模式下不读 stdin、lines=0，只留一行输入框
    fuzzel --dmenu --password --prompt-only="密码 $1: " --width=32
}

nmcli device wifi rescan >/dev/null 2>&1 &
sleep 1.5

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
    ssid="$(fuzzel --dmenu --prompt-only='网络名 (SSID): ' --width=32)"
    [ -z "$ssid" ] && exit 0
    pass="$(prompt_pass "$ssid")"
    [ -z "$pass" ] && exit 0
    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify "已连接" "$ssid"
    else
        notify "连接失败" "$ssid"
    fi
    exit 0
fi

ssid="${choice%% (*}"

# 已保存的连接：直接连；失败（比如密码变了）就弹密码框重连
if nmcli -t -f NAME connection show 2>/dev/null | grep -qxF "$ssid"; then
    if nmcli connection up "$ssid" >/dev/null 2>&1; then
        notify "已连接" "$ssid"
    else
        pass="$(prompt_pass "$ssid")"
        if [ -n "$pass" ]; then
            if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
                notify "已连接" "$ssid"
            else
                notify "连接失败" "$ssid"
            fi
        fi
    fi
    exit 0
fi

# 查这个网络是否需要密码
sec=""
for line in "${lines[@]}"; do
    IFS=: read -r s _ se <<< "$line"
    if [ "$s" = "$ssid" ]; then sec="$se"; break; fi
done

if [ -n "$sec" ]; then
    # 加密网络：弹小密码框
    pass="$(prompt_pass "$ssid")"
    [ -z "$pass" ] && exit 0
    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify "已连接" "$ssid"
    else
        notify "连接失败（密码错误？）" "$ssid"
    fi
else
    # 开放网络：直接连
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify "已连接" "$ssid"
    else
        notify "连接失败" "$ssid"
    fi
fi
