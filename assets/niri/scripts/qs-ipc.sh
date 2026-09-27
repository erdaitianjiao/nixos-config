#!/usr/bin/env bash
# 调 Quickshell 的 IPC：qs-ipc.sh <target> <method> [args...]
#
#   qs-ipc.sh launcher toggle      # Mod+D
#   qs-ipc.sh power-menu toggle    # Mod+Backspace
#   qs-ipc.sh notif-center toggle  # 通知中心
#
# 两个 shell 共用同一套 niri 键位，但 IPC 名字不一样，这里做一层兼容映射：
#
#   我们自研 clavis-style       上游 Clavis
#   ───────────────────────     ────────────────────────────────
#   launcher toggle/open/close  spotlight toggle/open/close
#   notif-center ...            sidebar ... dashboard（通知在 dashboard 侧栏里）
#   power-menu toggle           power-menu toggle   ← 同名同签名，不用映射
#   lock open / isLocked        lock open / isLocked ← 同名同签名，不用映射
#
# ⚠️ nix 的 makeBinaryWrapper 把 comm 改成 .quickshell-wra；而且 Quickshell 是用
#    裸名启动的（argv[0] 不含路径），所以匹配要看 comm 或 cmdline 开头，
#    不能只写 pkill -f '/bin/quickshell'。没在跑就静默退出。
set -u

pid="$(pgrep -x .quickshell-wra 2>/dev/null | head -1)"
[ -z "$pid" ] && pid="$(pgrep -f '^quickshell' 2>/dev/null | head -1)"
[ -z "$pid" ] && exit 0

# 当前跑的是哪个 shell（cmdline：-c clavis vs -c clavis-style）。
# clavis-style 要先匹配，否则它也会命中 *clavis*。
shell_cmd="$(pgrep -af quickshell 2>/dev/null | grep -v pgrep | head -1)"
case "$shell_cmd" in
    *clavis-style*) ;;
    *clavis*)
        case "${1:-} ${2:-}" in
            "launcher toggle")     set -- spotlight toggle ;;
            "launcher open")       set -- spotlight open ;;
            "launcher close")      set -- spotlight close ;;
            "notif-center toggle") set -- sidebar toggle dashboard ;;
            "notif-center open")   set -- sidebar open dashboard ;;
            "notif-center close")  set -- sidebar close dashboard ;;
        esac
        ;;
esac

exec qs ipc --pid "$pid" call "$@"
