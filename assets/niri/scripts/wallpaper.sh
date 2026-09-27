#!/usr/bin/env bash
# 壁纸循环：wallpaper.sh [next|prev|random]
# 优先用 ~/entertaiment/picture，没有就回退到自带的 ~/.config/niri/wallpapers
set -euo pipefail

dir="${NIRI_WALLPAPER_DIR:-$HOME/entertaiment/picture}"
[ -d "$dir" ] || dir="$HOME/.config/niri/wallpapers"

state="$HOME/.cache/niri-wallpaper"
mode="${1:-random}"

mapfile -t pics < <(find -L "$dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)

n="${#pics[@]}"
if [ "$n" -eq 0 ]; then
    echo "在 $dir 没找到图片 (jpg/jpeg/png)" >&2
    exit 1
fi

# 当前壁纸：优先读状态文件，其次从 swaybg 进程参数里取
cur="$(cat "$state" 2>/dev/null || true)"
if [ -z "$cur" ] || [ ! -f "$cur" ]; then
    cur="$(pgrep -a swaybg 2>/dev/null | sed -n 's/.*swaybg -i \([^ ]*\).*/\1/p' | head -1 || true)"
fi

# 在列表里定位当前壁纸
idx=0
if [ -n "$cur" ]; then
    for i in "${!pics[@]}"; do
        if [ "${pics[$i]}" = "$cur" ]; then idx=$i; break; fi
    done
fi

case "$mode" in
    next)   idx=$(( (idx + 1) % n )) ;;
    prev)   idx=$(( (idx - 1 + n) % n )) ;;
    random) idx=$(( RANDOM % n )) ;;
    *)
        echo "用法: wallpaper.sh [next|prev|random]" >&2
        exit 1
        ;;
esac

pic="${pics[$idx]}"
# 壁纸现在由 Quickshell 渲染（components/Wallpaper.qml）：本脚本只负责
# 挑图 + 把路径写进状态文件，它 watchChanges 到之后自己交叉淡入。
# 不再起 swaybg —— 顺便永久避开 home-manager wrapper 把 comm 改成
# .swaybg-wrapped、导致 `pkill -x swaybg` 匹配不到、进程越攒越多的问题。
printf '%s\n' "$pic" > "$state"

# 如果当前跑的是上游 Clavis shell，也让它切到同一张 —— Clavis 有自己的
# wallpaper 服务（它渲染、自己存 config），不会读我们这个状态文件。
# 两者靠 cmdline 区分：clavis-style（我们的） vs clavis（上游）。
# 先匹配 clavis-style，否则它也会命中 *clavis*。
shell_cmd="$(pgrep -af quickshell 2>/dev/null | grep -v pgrep | head -1)"
case "$shell_cmd" in
    *clavis-style*) ;;
    *clavis*)
        pid="$(pgrep -x .quickshell-wra 2>/dev/null | head -1)"
        if [ -n "$pid" ]; then
            qs ipc --pid "$pid" call wallpaper set "$pic" >/dev/null 2>&1 || true
        fi
        ;;
esac

echo "$pic"
