#!/usr/bin/env bash
# 调 Quickshell 的 IPC：qs-ipc.sh <target> <method> [args...]
#
#   qs-ipc.sh launcher toggle      # Mod+D
#   qs-ipc.sh power-menu toggle    # Mod+Backspace
#   qs-ipc.sh notif-center toggle  # 通知中心
#
# ⚠️ nix 的 makeBinaryWrapper 把 comm 改成 .quickshell-wra；而且 Quickshell 是用
#    裸名启动的（argv[0] 不含路径），所以匹配要看 comm 或 cmdline 开头，
#    不能只写 pkill -f '/bin/quickshell'。没在跑就静默退出。
set -u

pid="$(pgrep -x .quickshell-wra 2>/dev/null | head -1)"
[ -z "$pid" ] && pid="$(pgrep -f '^quickshell' 2>/dev/null | head -1)"
[ -z "$pid" ] && exit 0

exec qs ipc --pid "$pid" call "$@"
