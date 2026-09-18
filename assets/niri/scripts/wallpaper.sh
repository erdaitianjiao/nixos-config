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
    cur="$(pgrep -a swaybg 2>/dev/null | sed -n 's/.*swaybg -i \([^ ]*\).*/\1/p' | head -1)"
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
pkill -x swaybg 2>/dev/null || true
nohup swaybg -i "$pic" -m fill >/dev/null 2>&1 &
echo "$pic" > "$state"
echo "$pic"
