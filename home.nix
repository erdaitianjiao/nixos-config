{ config, lib, pkgs, ... }: {
  home.username = "tianjiao";
  home.homeDirectory = "/home/tianjiao";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # 媒体
    vlc
    feh
    # 办公
    libreoffice
    # 实用工具
    fastfetch
    flameshot
    ripgrep              # rg
    # 音乐
    go-musicfox          # 网易云 TUI 客户端
    # 通讯(unfree,腾讯官方 Linux 版)
    wechat
  ];

  # Fcitx5：英文键盘 + 雾凇拼音，默认使用雾凇。
  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=rime

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  # KDE Plasma 外观：Breeze Light + Tela + Layan + WhiteSur。
  # 用 kwriteconfig6 写入各应用共同读取的 KDE 全局配置。
  home.activation.kdeGlobalTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kwrite="${pkgs.kdePackages.kconfig}/bin/kwriteconfig6"
    "$kwrite" --file kdeglobals --group General --key ColorScheme BreezeLight
    "$kwrite" --file kdeglobals --group KDE --key widgetStyle Breeze
    "$kwrite" --file kdeglobals --group Icons --key Theme Tela
    "$kwrite" --file kcminputrc --group Mouse --key cursorTheme Breeze_Light
    "$kwrite" --file plasmarc --group Theme --key name Layan
    "$kwrite" --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
    "$kwrite" --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__WhiteSur
  '';
}
