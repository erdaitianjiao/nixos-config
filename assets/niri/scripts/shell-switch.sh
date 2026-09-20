#!/usr/bin/env bash
# 在 waybar 和 Quickshell(clavis-style) 之间来回切换。
#
# ⚠️ nix 的 makeBinaryWrapper 会把进程名改成 `.waybar-wrapped` /
# `.quickshell-wra` / `.mako-wrapped`，所以 `pkill -x waybar` 是无效的。
#
# mako 与 Quickshell 的 NotificationServer 都抢 org.freedesktop.Notifications，
# 同时只能有一个，所以切换时连带处理 mako。
set -u

QSCONFIG="${QSCONFIG:-clavis-style}"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a shell "Shell" "$1" 2>/dev/null
    return 0
}

stop_mako() {
    pkill -x .mako-wrapped 2>/dev/null || pkill -x mako 2>/dev/null
    return 0
}

start_mako() {
    if command -v mako >/dev/null 2>&1; then
        setsid mako >/dev/null 2>&1 &
    fi
    return 0
}

start_quickshell() {
    pkill -f '^waybar' 2>/dev/null
    stop_mako
    sleep 0.4
    setsid quickshell -c "$QSCONFIG" >/dev/null 2>&1 &
    sleep 2
    if pgrep -f '/bin/quickshell' >/dev/null 2>&1; then
        notify "Quickshell · $QSCONFIG"
    else
        notify "Quickshell 启动失败，回退 waybar"
        setsid waybar >/dev/null 2>&1 &
        start_mako
    fi
}

start_waybar() {
    pkill -f '/bin/quickshell' 2>/dev/null
    sleep 0.4
    setsid waybar >/dev/null 2>&1 &
    start_mako
    notify "waybar"
}

if pgrep -f '/bin/quickshell' >/dev/null 2>&1; then
    start_waybar
else
    start_quickshell
fi
