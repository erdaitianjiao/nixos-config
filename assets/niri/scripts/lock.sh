#!/usr/bin/env bash
# 锁屏统一入口：给 niri 快捷键 / swayidle / 其它脚本调用。
#
#   lock.sh             # 上锁（Quickshell 会话锁；没跑 Quickshell 时回退 hyprlock）
#   lock.sh --is-locked # 已锁返回 0，否则返回 1
#
# Quickshell 的锁屏通过 IPC 触发：`qs ipc call lock open`。
# 用 --pid 精确选中正在跑的 clavis-style 实例，避免匹配到抓拍子进程。
set -u
export PATH="$HOME/.local/bin:/etc/profiles/per-user/${USER:-$(id -un)}/bin:/run/current-system/sw/bin:/usr/bin:/bin"

pid="$(pgrep -x .quickshell-wra 2>/dev/null | head -1)"
[ -z "${pid:-}" ] && pid="$(pgrep -f 'quickshell' 2>/dev/null | head -1)"

if [ "${1:-}" = "--is-locked" ]; then
    [ -n "${pid:-}" ] || exit 1
    out="$(qs ipc --pid "$pid" call lock isLocked 2>/dev/null)" || exit 1
    case "$out" in *true*) exit 0 ;; *) exit 1 ;; esac
fi

if [ -n "${pid:-}" ] && qs ipc --pid "$pid" call lock open >/dev/null 2>&1; then
    exit 0
fi

# 回退：Quickshell 未运行 / IPC 失败时用 hyprlock，保证不会漏锁。
if command -v hyprlock >/dev/null 2>&1; then
    exec hyprlock
fi

exit 1
