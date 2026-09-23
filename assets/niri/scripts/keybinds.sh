#!/usr/bin/env bash
# 快捷键速查 — 用 fuzzel 显示，替代 niri 自带的丑 overlay
# 按 Esc 关闭

cat <<'EOF' | fuzzel --dmenu --prompt "󰌌  Keys "
Super + Enter / T      打开终端 (kitty)
Super + D              应用启动器 (fuzzel)
Super + O              窗口总览
Super + Q              关闭窗口
Super + H/J/K/L        聚焦 左/下/上/右
Super + Ctrl + H/J/K/L 移动窗口
Super + 1~9            切换工作区
Super + Tab            上一个工作区
Super + V              浮动窗口开关
Super + W              列标签页显示
Super + F              列最大化
Super + Shift + F      全屏
Super + M              窗口撑满屏幕
Super + C              居中当前列
Super + R              切换列宽
Super + Minus/Equal    调列宽
Print                  截图
Super + Backspace      电源菜单
Super + Shift + P      熄屏 (DPMS 关屏，动一下鼠标/键盘唤醒)
Super + Shift + E      退出 niri
Super + Alt + L        锁屏
Ctrl + Space           切换输入法 (雾凇拼音)
Super + Shift + B      切换日/夜主题
Super + Shift + W      下一张壁纸
Super + Shift + S      上一张壁纸
EOF
