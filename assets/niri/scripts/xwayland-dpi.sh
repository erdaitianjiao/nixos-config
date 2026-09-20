#!/bin/sh
# 让 X11 侧的 fcitx5 候选窗跟着「当前聚焦的输出」缩放。
#
# 背景（X11 的硬伤）：整个 X server 只有一个 DPI/缩放，没法按屏幕。niri 通过
# xwayland-satellite 跑 X11，而 satellite 对混合缩放屏幕的策略是「取最小的那个
# 缩放」并通过 XSETTINGS 广播 —— 但：
#   1) 它给的是全局固定值（你这里 min(1.5,1.25)=1.25），从外接屏挪到内置屏不会变；
#   2) fcitx5 classicui 的 XCB 后端不读 XSETTINGS，只读 X resource 里的 Xft.dpi，
#      而 satellite 0.8.2 不写 RESOURCE_MANAGER（上游 #477 才加），所以它默认卡在
#      96dpi/1x —— 这就是微信里候选窗偏小的根源。
#
# 变通办法：X11 只有全局 DPI，但 niri 有「当前聚焦输出」。切屏时把 Xft.dpi 设成
# 该输出 scale*96，fcitx5 监听到 root 窗口 RESOURCE_MANAGER 变化会自动重读，
# 于是候选窗在哪个屏就按哪个屏缩放（1.25 -> 120，1.5 -> 144）。
set -u

current=""
while :; do
    scale=$(niri msg --json focused-output 2>/dev/null |
        grep -o '"scale":[0-9.]*' | head -1 | cut -d: -f2)
    if [ -n "${scale:-}" ]; then
        dpi=$(awk -v s="$scale" 'BEGIN { printf "%d", s * 96 + 0.5 }')
        if [ "$dpi" != "$current" ]; then
            # XWayland 按需启动、重启会丢 resource database，失败就一直重试。
            if printf 'Xft.dpi: %s\n' "$dpi" | xrdb -merge 2>/dev/null; then
                current="$dpi"
            fi
        fi
    fi
    sleep 1
done
