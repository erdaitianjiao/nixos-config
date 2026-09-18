# ─────────────────────────────────────────────────────────────
# niri 桌面环境 —— home-manager 模块（配置文件声明式管理）
#
# 切换主题：把下面的 theme 改成 "light" 或 "dark"，然后 nixos-rebuild switch
#   light = Matcha 浅绿（白天）
#   dark  = Tokyo Night（夜间）
# ─────────────────────────────────────────────────────────────
{ config, lib, pkgs, ... }:

let
  theme = "light";

  assets = ./assets/niri;
  exe = name: { source = "${assets}/scripts/${name}"; executable = true; };
in {
  xdg.configFile = {
    # ── 各程序配置（跟随主题）──
    "niri/config.kdl".source     = "${assets}/${theme}/config.kdl";
    "kitty/kitty.conf".source    = "${assets}/${theme}/kitty.conf";
    "waybar/config.jsonc".source = "${assets}/waybar-config.jsonc";
    "waybar/style.css".source    = "${assets}/${theme}/style.css";
    "fuzzel/fuzzel.ini".source   = "${assets}/${theme}/fuzzel.ini";
    "mako/config".source         = "${assets}/${theme}/mako.conf";

    # ── 辅助脚本 ──
    "niri/keybinds.sh"           = exe "keybinds.sh";
    "niri/wallpaper.sh"          = exe "wallpaper.sh";
    "waybar/wifi-menu.sh"        = exe "wifi-menu.sh";
    "waybar/bluetooth-menu.sh"   = exe "bluetooth-menu.sh";
    "waybar/bluetooth-toggle.sh" = exe "bluetooth-toggle.sh";
    "waybar/powermenu.sh"        = exe "powermenu.sh";

    # ── 壁纸 ──
    "niri/wallpapers/matcha.png".source      = "${assets}/wallpapers/matcha.png";
    "niri/wallpapers/tokyo-night.png".source = "${assets}/wallpapers/tokyo-night.png";
  };
}
