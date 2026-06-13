{ config, pkgs, ... }: {
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
    # 游戏(unfree)
    steam
    # 通讯(unfree,腾讯官方 Linux 版)
    wechat
  ];
}
