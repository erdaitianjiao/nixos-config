#!/usr/bin/env bash
# Super+Backspace → 开关 Quickshell 的电源菜单。
# 用 --pid 选中正在跑的 quickshell 实例，不依赖它是以 `-c clavis-style`
# 还是 `-p <路径>` 启动的；没在跑就静默退出。
#
# 注意：nix 的 makeBinaryWrapper 让进程 comm 变成 .quickshell-wra（15 字符截断），
# 而 cmdline 可能是裸 `quickshell -c ...`（不含路径），所以两种都试。
set -u

pid="$(pgrep -x .quickshell-wra 2>/dev/null | head -1)"
[ -z "$pid" ] && pid="$(pgrep -f 'quickshell' 2>/dev/null | head -1)"
[ -z "$pid" ] && exit 0

exec qs ipc --pid "$pid" call power-menu toggle
