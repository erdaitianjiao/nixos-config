{ config, lib, pkgs, ... }: {
  imports = [ ./niri.nix ];

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
    # 通讯：微信已改用 Flathub 的 com.tencent.WeChat（不再用 nixpkgs 的 AppImage）

    # ── Quickshell 实验 shell (clavis-style) ──
    quickshell
  ];

  # ── 闲置自动锁屏 / 熄屏（省电，swayidle）────────────────────
  # niri 自身只有手动的 power-off-monitors（Mod+Shift+P），没有 idle 定时器；
  # 自动熄屏交给 swayidle。niri 实现了 idle-inhibit，看视频 / 全屏播放时会自动
  # 暂停计时，不会看到一半黑屏。
  #
  # 时间线（改数字即可调时长，单位秒）：
  #   300s           → 锁屏（Quickshell 会话锁，见 ~/.config/niri/lock.sh）
  #   301s           → DPMS 关屏（晚 1 秒，等锁屏画面画完再关，避免闪一下）
  #   睡眠前 / logind 锁会话 → 先锁屏
  # 唤醒：动键盘 / 鼠标时 niri 自动点亮屏幕（见 niri 源码 should_activate_monitors），
  # 所以不需要额外的 resume 命令。
  #
  # 它绑定到 niri.service（niri-session 启动的 systemd 用户服务），随会话启动/退出，
  # 查看状态：systemctl --user status swayidle
  #
  # ⚠️ home-manager 给这个单元设的 PATH 只有 bash，所以下面命令必须写绝对路径，
  #    否则会 command not found。
  services.swayidle = {
    enable = true;
    systemdTargets = [ "niri.service" ];
    timeouts = [
      {
        timeout = 300;
        # Quickshell 会话锁（默认风格），入口脚本内部会走 IPC；
        # swayidle 带了 -w（等命令退出），所以 & 到后台，避免卡住事件循环。
        command = "${config.home.homeDirectory}/.config/niri/lock.sh &";
      }
      {
        timeout = 301;
        command = "${lib.getExe pkgs.niri} msg action power-off-monitors";
      }
    ];
    events = {
      # 睡前：后台起锁屏，再等 1 秒确保锁屏已生效才放行挂起。
      before-sleep = "${config.home.homeDirectory}/.config/niri/lock.sh & ${pkgs.coreutils}/bin/sleep 1";
      lock = "${config.home.homeDirectory}/.config/niri/lock.sh &";
    };
  };

  # 微信 (Flatpak) 字体。
  # flatpak 沙箱里的 fontconfig 读不到宿主 ~/.config/fontconfig，
  # 只会读它自己的 XDG_CONFIG_HOME（即 ~/.var/app/<appid>/config）下的
  # fontconfig/fonts.conf，所以必须写到这里。
  # 微信用 "Microsoft YaHei, PingFang SC, ... , Noto Sans CJK SC, sans-serif"
  # 这套字体栈，Linux 上前几个都没有，会被替换成 DejaVu Sans，中英混排很怪。
  # 下面把它整条指向 Noto Sans CJK SC；想换字体改文件里的字体名即可。
  home.file.".var/app/com.tencent.WeChat/config/fontconfig/fonts.conf" = {
    force = true;
    source = ./assets/wechat-fonts.conf;
  };

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
  # 注意：fcitx5-rime 的 PreeditMode 三种含义（见上游 rimestate.cpp）：
  #   "Composing text" → 只把拼音当「客户端预编辑」交给应用自己画；
  #                      QQ/微信/Electron 常常不画 → 哪里都看不到拼音。
  #   "Commit preview" → 候选窗里画拼音，同时让应用内联显示候选词预览。
  #   "Do not show"    → 候选窗里画拼音，应用里不显示内联预览。
  # 所以不要用 "Composing text"（默认值是它，这就是你看不到拼音的原因）。
  xdg.configFile."fcitx5/conf/rime.conf" = {
    force = true;
    text = ''
      PreeditMode="Commit preview"
      PreeditCursorPositionAtBeginning=False
    '';
  };

  # X11/XWayland 的 GTK 程序走 fcitx im module；Wayland 的 GTK3/4 会忽略它
  # 而用内置 text-input-v3（见 configuration.nix），所以不用全局 GTK_IM_MODULE。
  # 这个文件同时被 KDE(kde-gtk-config) 写入主题/字体等，只能“合并”这一个键，
  # 不能用 xdg.configFile 整体覆盖，否则会把 KDE 的设置冲掉。
  home.activation.gtkImModule = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for v in 3.0 4.0; do
      mkdir -p "$HOME/.config/gtk-$v"
      ${pkgs.crudini}/bin/crudini --set "$HOME/.config/gtk-$v/settings.ini" Settings gtk-im-module fcitx
    done
    if [ ! -f "$HOME/.gtkrc-2.0" ] || ! grep -q '^gtk-im-module=' "$HOME/.gtkrc-2.0"; then
      echo 'gtk-im-module="fcitx"' >> "$HOME/.gtkrc-2.0"
    fi
  '';

  # ── Quickshell 的 bar / 通知（clavis-style）──
  # 配置来源在 assets/quickshell/clavis-style，由 niri 开机自启 `quickshell -c clavis-style`。
  xdg.configFile."quickshell/clavis-style" = {
    source = ./assets/quickshell/clavis-style;
    recursive = true;
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
    force = true;
    source = ./assets/fcitx5-themes/Material-Color-deepPurple;
    recursive = true;
  };
  xdg.dataFile."fcitx5/themes/Material-Color-orange" = {
    force = true;
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
