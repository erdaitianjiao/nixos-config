#!/usr/bin/env bash
# 在 waybar 和 Quickshell(clavis-style) 之间来回切换。
#
# ⚠️ nix 的 makeBinaryWrapper 会把进程名改成 `.waybar-wrapped` /
# `.quickshell-wra`，所以 `pkill -x waybar` 是无效的，必须按 cmdline 匹配。
set -u

QSCONFIG="${QSCONFIG:-clavis-style}"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a shell "Shell" "$1" 2>/dev/null
    return 0
}

start_quickshell() {
    pkill -f '^waybar' 2>/dev/null
    sleep 0.4
    setsid quickshell -c "$QSCONFIG" >/dev/null 2>&1 &
    sleep 2
    if pgrep -f '/bin/quickshell' >/dev/null 2>&1; then
        notify "Quickshell · $QSCONFIG"
    else
        notify "Quickshell 启动失败，回退 waybar"
        setsid waybar >/dev/null 2>&1 &
    fi
}

start_waybar() {
    pkill -f '/bin/quickshell' 2>/dev/null
    sleep 0.4
    setsid waybar >/dev/null 2>&1 &
    notify "waybar"
}

if pgrep -f '/bin/quickshell' >/dev/null 2>&1; then
    start_waybar
else
    start_quickshell
fi
