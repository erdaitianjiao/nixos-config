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

  # 在候选窗中显示正在输入的拼音编码。
  xdg.configFile."fcitx5/conf/rime.conf" = {
    force = true;
    text = ''
      PreeditMode="Composing text"
      PreeditCursorPositionAtBeginning=False
    '';
  };

  # 与主力机一致：只使用 Classic UI，避免与 Plasma Kimpanel 重复显示候选窗。
  xdg.configFile."fcitx5/addon/classicui.conf" = {
    force = true;
    text = ''
      [Addon]
      UIPriority=100
    '';
  };
  xdg.configFile."fcitx5/addon/kimpanel.conf" = {
    force = true;
    text = ''
      [Addon]
      Enabled=False
      Load=False
    '';
  };
  xdg.configFile."fcitx5/conf/classicui.conf" = {
    force = true;
    source = ./assets/fcitx5-classicui.conf;
  };

  xdg.dataFile."fcitx5/themes/Material-Color-deepPurple" = {
    source = ./assets/fcitx5-themes/Material-Color-deepPurple;
    recursive = true;
  };
  xdg.dataFile."fcitx5/themes/Material-Color-orange" = {
    source = ./assets/fcitx5-themes/Material-Color-orange;
    recursive = true;
  };

  # fcitx5-rime 自带的空 default.yaml 会覆盖词库包中的同名文件，
  # 因此恢复雾凇的完整默认配置，并显式选择雾凇方案。
  xdg.dataFile."fcitx5/rime/default.yaml" = {
    force = true;
    source = "${pkgs.rime-ice.src}/default.yaml";
  };
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    force = true;
    text = ''
      patch:
        schema_list:
          - schema: rime_ice
    '';
  };

  # KDE Plasma 外观：Breeze Light + Tela + Layan + WhiteSur。
  # 用 kwriteconfig6 写入各应用共同读取的 KDE 全局配置。
  home.activation.kdeGlobalTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kwrite="${pkgs.kdePackages.kconfig}/bin/kwriteconfig6"
    "$kwrite" --file kdeglobals --group General --key ColorScheme BreezeLight
    "$kwrite" --file kdeglobals --group KDE --key widgetStyle Breeze
    "$kwrite" --file kdeglobals --group KDE --key LookAndFeelPackage mix-kde-tianjiao
    "$kwrite" --file kdeglobals --group Icons --key Theme Tela
    "$kwrite" --file kcminputrc --group Mouse --key cursorTheme Breeze_Light
    "$kwrite" --file plasmarc --group Theme --key name Layan
    "$kwrite" --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
    "$kwrite" --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__WhiteSur
    "$kwrite" --file baloofilerc --group "Basic Settings" --key "Indexing-Enabled" false
  '';

  xdg.dataFile."plasma/look-and-feel/mix-kde-tianjiao" = {
    source = ./assets/plasma-look-and-feel/mix-kde-tianjiao;
    recursive = true;
  };
}
