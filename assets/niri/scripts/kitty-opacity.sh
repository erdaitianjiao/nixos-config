#!/usr/bin/env bash
# 循环调整所有 kitty 实例的背景透明度：0.50 → 0.30 → 0.90 → 0.70 → 0.50
#
# 由 niri 的 Super+Shift+/ 调用（见 assets/niri/*/config.kdl）。
# 走 kitty 的 remote control（kitty.conf 里 allow_remote_control yes），
# 因为 kitty 内置的 l/m 只能单向增减，没法一键循环。
set -u

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/clavis-kitty-opacity"
mkdir -p "$state_dir"
state_file="$state_dir/current"

cur="$(cat "$state_file" 2>/dev/null || echo 0.50)"
case "$cur" in
    0.50) next=0.30 ;;
    0.30) next=0.90 ;;
    0.90) next=0.70 ;;
    0.70) next=0.50 ;;
    *)    next=0.50 ;;
esac
printf '%s' "$next" > "$state_file"

# kitty 的 socket 可能在 XDG_RUNTIME_DIR 或 /tmp 下（不同版本/配置）
found=0
for dir in "${XDG_RUNTIME_DIR:-}" /tmp; do
    [ -n "$dir" ] || continue
    for sock in "$dir"/kitty-*; do
        [ -S "$sock" ] || continue
        if kitty @ --to "unix:$sock" set-background-opacity "$next" >/dev/null 2>&1; then
            found=1
        fi
    done
done

if [ "$found" = 1 ]; then
    notify-send -a kitty "kitty 透明度" "$next"
else
    notify-send -a kitty "kitty 透明度" "没有运行中的 kitty"
fi
