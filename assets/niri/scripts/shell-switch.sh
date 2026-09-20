#!/usr/bin/env bash
# 在 waybar 和 Quickshell(clavis-style) 之间来回切换；也用作开机自启。
#
# ⚠️ nix 的 makeBinaryWrapper 会把进程名改成 `.waybar-wrapped` /
# `.quickshell-wra` / `.mako-wrapped`；而且本脚本是用裸名
# `quickshell -c ...` 启动的，argv[0] 不含路径。
# 所以匹配要同时看 comm 和 cmdline 的开头，不能只写 pkill -f '/bin/quickshell'。
#
# mako 与 Quickshell 的 NotificationServer 都抢 org.freedesktop.Notifications，
# 同时只能有一个，所以切换时连带处理 mako。
set -u

QSCONFIG="${QSCONFIG:-clavis-style}"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a shell "Shell" "$1" 2>/dev/null
    return 0
}

qs_running() {
    pgrep -x .quickshell-wra >/dev/null 2>&1 || pgrep -f '^quickshell' >/dev/null 2>&1
}

stop_quickshell() {
    pkill -x .quickshell-wra 2>/dev/null || pkill -f '^quickshell' 2>/dev/null
    return 0
}

stop_waybar() {
    pkill -x .waybar-wrapped 2>/dev/null || pkill -f '^waybar' 2>/dev/null
    return 0
}

stop_mako() {
    pkill -x .mako-wrapped 2>/dev/null || pkill -f '^mako' 2>/dev/null
    return 0
}

start_mako() {
    if command -v mako >/dev/null 2>&1; then
        setsid mako >/dev/null 2>&1 &
    fi
    return 0
}

start_quickshell() {
    stop_waybar
    stop_mako
    sleep 0.4
    setsid quickshell -c "$QSCONFIG" >/dev/null 2>&1 &
    sleep 2
    if qs_running; then
        notify "Quickshell · $QSCONFIG"
    else
        notify "Quickshell 启动失败，回退 waybar"
        setsid waybar >/dev/null 2>&1 &
        start_mako
    fi
}

start_waybar() {
    stop_quickshell
    sleep 0.4
    setsid waybar >/dev/null 2>&1 &
    start_mako
    notify "waybar"
}

if qs_running; then
    start_waybar
else
    start_quickshell
fi
