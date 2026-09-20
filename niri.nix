# ─────────────────────────────────────────────────────────────
# niri 桌面环境 —— home-manager 模块（配置文件声明式管理）
#
# 切换主题：把下面的 theme 改成 "light" 或 "dark"，然后 nixos-rebuild switch
#   light = Matcha 浅绿（白天）
#   dark  = Tokyo Night（夜间）
#
# bar / 通知都交给 Quickshell（assets/quickshell/clavis-style），
# 不再用 waybar / mako；相关辅助脚本统一放 ~/.config/niri/。
# ─────────────────────────────────────────────────────────────
{ config, lib, pkgs, ... }:

let
  theme = "light";

  assets = ./assets/niri;
  exe = name: { source = "${assets}/scripts/${name}"; executable = true; };
in {
  xdg.configFile = {
    # ── 各程序配置（跟随主题）──
    "niri/config.kdl".source   = "${assets}/${theme}/config.kdl";
    "kitty/kitty.conf".source  = "${assets}/${theme}/kitty.conf";
    "fuzzel/fuzzel.ini".source = "${assets}/${theme}/fuzzel.ini";

    # ── 辅助脚本 ──
    "niri/keybinds.sh"          = exe "keybinds.sh";
    "niri/wallpaper.sh"         = exe "wallpaper.sh";
    "niri/bar-watch.sh"         = exe "bar-watch.sh";
    "niri/xwayland-dpi.sh"      = exe "xwayland-dpi.sh";
    "niri/power-menu.sh"        = exe "power-menu.sh";
    "niri/wifi-menu.sh"         = exe "wifi-menu.sh";
    "niri/bluetooth-menu.sh"    = exe "bluetooth-menu.sh";
    "niri/bluetooth-toggle.sh"  = exe "bluetooth-toggle.sh";

    # ── 壁纸 ──
    "niri/wallpapers/matcha.png".source      = "${assets}/wallpapers/matcha.png";
    "niri/wallpapers/tokyo-night.png".source = "${assets}/wallpapers/tokyo-night.png";
  };
}
