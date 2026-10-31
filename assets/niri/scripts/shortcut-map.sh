#!/usr/bin/env bash
# 快捷键速查：
#   - Clavis 在跑 → 用 Clavis 内置的 shortcut-map（读 niri 实际 binds，Material 风格）
#   - Clavis 没跑   → 回退到 fuzzel 版 keybinds.sh
#
# 注意：Clavis 的配置是通过 XDG_CONFIG_DIRS 指定的，`qs -c clavis ipc` 找不到实例，
# 必须像 lock.sh 一样用 --pid 精确选中。
set -u
export PATH="$HOME/.local/bin:/etc/profiles/per-user/${USER:-$(id -un)}/bin:/run/current-system/sw/bin:/usr/bin:/bin"

pid="$(pgrep -f 'quickshell -c clavis' 2>/dev/null | head -1)"
if [ -n "${pid:-}" ]; then
    if qs ipc --pid "$pid" call shortcut-map toggle >/dev/null 2>&1; then
        exit 0
    fi
fi

exec "$HOME/.config/niri/keybinds.sh"
