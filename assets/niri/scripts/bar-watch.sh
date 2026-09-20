#!/usr/bin/env bash
# waybar/Quickshell + 壁纸守护。
#
# 两个职责：
#  1) 壁纸：swww 在输出重连（盒盖/开盖、插拔屏）后会把该屏重置成纯色(黑)。niri 26.04
#     的事件流里【没有】输出变化事件，所以这里【轮询】检查 `swww query`：只要有屏在
#     显示 "color:"(纯色) 就重新贴一遍缓存的壁纸。
#  2) bar：输出集合变化后重启当前在跑的那条 bar（老 waybar 热插拔后会卡在重绘；
#     Quickshell 同理）。Quickshell 还是 waybar 由谁在跑决定。
#
#   bar-watch.sh            # 常驻（spawn-at-startup 用）
#   bar-watch.sh restart    # 立即重启 bar + 重贴壁纸
set -uo pipefail
export PATH="$HOME/.local/bin:/usr/bin:/bin"

apply_wallpaper() {
	local f="$HOME/.cache/niri-wallpaper" pic
	[ -f "$f" ] || return 0
	pic="$(cat "$f" 2>/dev/null)" || return 0
	[ -n "$pic" ] && [ -e "$pic" ] || return 0
	swww img --transition-type none "$pic" >/dev/null 2>&1 || true
}

# 有任何输出在显示纯色(黑) -> 返回 0
swww_has_blank() {
	command -v swww >/dev/null 2>&1 || return 1
	swww query 2>/dev/null | grep -q 'displaying: color:'
}

# 输出变化后重启「当前这条 bar」：Quickshell 或 waybar
# ⚠️ nix 的 wrapper 把 comm 改成 .waybar-wrapped / .quickshell-wra；
#    Quickshell 是用裸名启动的（argv[0] 不含路径），所以匹配要看 comm 或
#    cmdline 开头，不能只写 pkill -f '/bin/quickshell'。
restart_bar() {
	if pgrep -x .quickshell-wra >/dev/null 2>&1 || pgrep -f '^quickshell' >/dev/null 2>&1; then
		pkill -x .quickshell-wra 2>/dev/null || pkill -f '^quickshell' 2>/dev/null || true
		sleep 0.5
		setsid quickshell -c "${QSCONFIG:-clavis-style}" >/dev/null 2>&1 &
	else
		pkill -x .waybar-wrapped 2>/dev/null || pkill -f '^waybar' 2>/dev/null || true
		sleep 0.3
		setsid waybar >/dev/null 2>&1 &
	fi
}

outputs_sig() {
	niri msg outputs 2>/dev/null | grep -E '^Output' | LC_ALL=C sort | tr '\n' '|'
}

case "${1:-watch}" in
	restart)
		restart_bar
		sleep 1
		apply_wallpaper
		exit 0
		;;
	watch) ;;
	*)
		echo "usage: $0 [watch|restart]" >&2
		exit 2
		;;
esac

prev="$(outputs_sig)"
while sleep 2; do
	# 壁纸自愈
	swww_has_blank && apply_wallpaper

	# bar 热插拔重启
	cur="$(outputs_sig)"
	if [ -n "$cur" ] && [ "$cur" != "$prev" ]; then
		prev="$cur"
		sleep 1
		restart_bar
		sleep 1
		apply_wallpaper
	fi
done
