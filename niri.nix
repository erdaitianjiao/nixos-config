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

  # slider-popup（点击弹滑块）需要的 Python + PyGObject 环境
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);

  # 用 wrapGAppsHook4 自动收集 GTK4/Graphene/cairo 等所有 GI typelib
  sliderPopup = pkgs.stdenv.mkDerivation {
    pname = "niri-slider-popup";
    version = "1";
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.wrapGAppsHook4 pkgs.gobject-introspection pkgs.makeWrapper ];
    buildInputs = [ pythonEnv pkgs.gtk4 ];

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${lib.makeBinPath [ pythonEnv pkgs.ddcutil pkgs.brightnessctl pkgs.wireplumber ]}
      )
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -m755 ${assets}/scripts/slider-popup $out/bin/slider-popup
    '';
  };
in {
  home.packages = [ sliderPopup ];

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
    "niri/bar-watch.sh"          = exe "bar-watch.sh";
    "waybar/wifi-menu.sh"        = exe "wifi-menu.sh";
    "waybar/bluetooth-menu.sh"   = exe "bluetooth-menu.sh";
    "waybar/bluetooth-toggle.sh" = exe "bluetooth-toggle.sh";
    "waybar/powermenu.sh"        = exe "powermenu.sh";

    # 音量/亮度点击弹窗滑块（转到 wrapGAppsHook 包装好的程序）
    "waybar/slider-popup" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        exec ${sliderPopup}/bin/slider-popup "$@"
      '';
    };

    # ── 壁纸 ──
    "niri/wallpapers/matcha.png".source      = "${assets}/wallpapers/matcha.png";
    "niri/wallpapers/tokyo-night.png".source = "${assets}/wallpapers/tokyo-night.png";
  };
}
