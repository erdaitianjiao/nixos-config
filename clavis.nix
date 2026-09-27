# ─────────────────────────────────────────────────────────────
# Clavis shell（上游 StatIndet/quickshell）—— 完整移植版。
#
# 和我们的自研 shell `clavis-style` 并存：
#   assets/quickshell/clavis-style/  ← 我们自己写的（默认在用）
#   assets/quickshell/clavis/        ← 上游源码，原样 vendored
#
# 源码打包在 packages/clavis-shell.nix（CMake + Qt6 native QML 插件）。
#
# 切换（也可以按 Mod+Shift+C）：
#   ~/.config/niri/clavis.sh clavis   # 起 Clavis
#   ~/.config/niri/clavis.sh ours     # 起回我们的 bar
#   ~/.config/niri/clavis.sh toggle   # 来回切
#   ~/.config/niri/clavis.sh status   # 看现在跑的是哪个
# ─────────────────────────────────────────────────────────────
{ config, lib, pkgs, inputs, ... }:

let
  clavis = pkgs.callPackage ./packages/clavis-shell.nix { };

  # 上游要求一个**外部** QML 模块 M3Shapes（Material 3 shapes，
  # androidx shape 库的 Qt 移植），上游 flake 已提供打包：
  #   https://github.com/soramanew/m3shapes
  # 上游默认用 clangStdenv，这里换回普通 stdenv 省一次 clang 下载。
  m3shapes = inputs.m3shapes.packages.${pkgs.stdenv.hostPlatform.system}.m3shapes.override {
    stdenv = pkgs.stdenv;
  };

  # QML 导入路径。
  # 注意两种前缀：Clavis 自己的插件装在 lib/qt6/qml，Qt 官方模块和
  # m3shapes 在 lib/qt-6/qml（多个横杠），两个都要给。
  clavisQmlPath = lib.concatStringsSep ":" [
    "${clavis}/lib/qt6/qml"
    "${m3shapes}/lib/qt-6/qml"
    "${pkgs.qt6.qtbase}/lib/qt-6/qml"
    "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
    "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
    "${pkgs.qt6.qtlottie}/lib/qt-6/qml"
    "${pkgs.qt6.qtlocation}/lib/qt-6/qml"
    "${pkgs.qt6.qtpositioning}/lib/qt-6/qml"
    "${pkgs.qt6.qtsvg}/lib/qt-6/qml"
  ];

  # 上游 packaging/dependencies.json 里的运行时依赖。
  # nixpkgs 里确实没有的（key-cli / awww / gpu-screen-recorder …）自动跳过 ——
  # 缺了只是对应功能降级（比如系统监控卡片、壁纸后端），不影响启动。
  optionalPkgs = names:
    builtins.filter (p: p != null)
      (map (n: if builtins.hasAttr n pkgs then pkgs.${n} else null) names);

in {
  home.packages = [
    clavis
    m3shapes

    # 图标字体：Clavis 的 UI 全靠 Material Symbols（Rounded/Outlined）
    pkgs.material-symbols

    # QML 运行时模块（QML2_IMPORT_PATH 里同时也要有）
    pkgs.qt6.qt5compat
    pkgs.qt6.qtlottie
    pkgs.qt6.qtlocation
    pkgs.qt6.qtpositioning
    pkgs.qt6.qtsvg
    # 天气地图用的 MapLibre
    pkgs.qt6Packages.maplibre-native-qt

    # 脚本 / 功能依赖
    pkgs.matugen # 主题色生成
    pkgs.brightnessctl # 内屏亮度
    pkgs.ddcutil # 外接屏亮度
    pkgs.grim # 截图
    pkgs.slurp # 录屏选区
    pkgs.wl-clipboard # 剪贴板
    pkgs.fd # Spotlight 文件搜索
    pkgs.ffmpeg # 录屏 / GIF 转换
    pkgs.imagemagick # 概览壁纸缓存
    pkgs.rclone # 云备份 / 上传
    pkgs.jq
    pkgs.which
    pkgs.libnotify
    pkgs.xdg-utils
    pkgs.glib # GSettings
    pkgs.gvfs # Dock 的回收站
    pkgs.networkmanager # nmcli
    pkgs.playerctl
    pkgs.python3
    pkgs.util-linux # flock
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
  ] ++ optionalPkgs [
    "awww" # 可选壁纸后端
    "gpu-screen-recorder"
    "hyprpicker"
    "xdg-terminal-exec"
    "key-cli" # 上游自家的系统指标后端，nixpkgs 没有
  ];

  # 启动 / 切换脚本。环境变量必须带上：
  #   XDG_CONFIG_DIRS  → 让 `quickshell -c clavis` 找到 $out/etc/xdg/quickshell/clavis
  #   QML2_IMPORT_PATH → 让 Clavis.* 插件和 M3Shapes 能被 import
  xdg.configFile."niri/clavis.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Clavis shell 启动器 / 与我们自研 bar 的切换器
      #   clavis.sh [clavis|ours|toggle|status]
      set -uo pipefail

      QML_PATH=${lib.escapeShellArg clavisQmlPath}
      CONFIG_DIRS=${lib.escapeShellArg "${clavis}/etc/xdg"}:/etc/xdg
      LOG=/tmp/clavis-shell.log

      # 现在跑的是哪个（两个都是 .quickshell-wra，靠 cmdline 区分）
      current() {
        local cmd
        cmd="$(pgrep -af 'quickshell' 2>/dev/null | grep -v pgrep | head -1)"
        case "$cmd" in
          *clavis-style*) printf 'ours' ;;
          "") printf 'none' ;;
          *) printf 'clavis' ;;
        esac
      }

      stop_all() {
        pkill -x .quickshell-wra 2>/dev/null
        sleep 0.4
      }

      start_ours() {
        stop_all
        setsid quickshell -c clavis-style >/dev/null 2>&1 &
      }

      start_clavis() {
        stop_all
        XDG_CONFIG_DIRS="$CONFIG_DIRS" \
        QML2_IMPORT_PATH="$QML_PATH" \
        QML_IMPORT_PATH="$QML_PATH" \
          setsid quickshell -c clavis >"$LOG" 2>&1 &
      }

      case "''${1:-toggle}" in
        clavis)
          start_clavis
          echo "started clavis (log: $LOG)"
          ;;
        ours)
          start_ours
          echo "started clavis-style (ours)"
          ;;
        toggle)
          if [ "$(current)" = clavis ]; then
            start_ours
            echo "switched to clavis-style (ours)"
          else
            start_clavis
            echo "switched to clavis (log: $LOG)"
          fi
          ;;
        status)
          echo "running: $(current)"
          ;;
        *)
          echo "usage: $0 [clavis|ours|toggle|status]" >&2
          exit 2
          ;;
      esac
    '';
  };
}
