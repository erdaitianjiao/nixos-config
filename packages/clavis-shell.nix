# Clavis shell（上游 https://github.com/StatIndet/quickshell）的 Nix 打包。
#
# 上游是 Arch 导向的：CMake 构建一组 native QML 插件（Clavis.Niri /
# Clavis.Files / Clavis.Weather / Clavis.Cava / Clavis.Media / …），
# QML 本体则按 XDG 配置目录的约定安装。这里保持它原有的布局：
#
#   native 插件        → $out/lib/qt6/qml/Clavis
#   QML 配置本体        → $out/etc/xdg/quickshell/clavis
#   systemd user unit  → $out/lib/systemd/user
#
# 所以运行时只要：
#   XDG_CONFIG_DIRS 带上 $out/etc/xdg        → `quickshell -c clavis` 能找到配置
#   QML2_IMPORT_PATH 带上 $out/lib/qt6/qml   → 能找到 Clavis.* 插件
#
# 注意：上游 C++ 只依赖 Qt6 + qtkeychain + libcava + pipewire + libudev。
# maplibre / QtLocation / lottie / qt5compat 只在 QML 运行时用到，是运行时
# 依赖，不出现在 buildInputs 里。
{ lib, stdenv, cmake, ninja, pkg-config, python3, patchelf, qt6, qt6Packages, libcava, pipewire, systemd, wayland, wayland-protocols, wayland-scanner, glib, libxkbcommon }:

stdenv.mkDerivation (finalAttrs: {
  pname = "clavis-shell";
  version = "2026.9.12";

  src = ../assets/quickshell/clavis;

  # 上游 core/CMakeLists.txt 会调 scripts/dev/generate-search-catalog.py
  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3
    # windowpreview 插件用 find_program 找 wayland-scanner
    wayland-scanner
    patchelf
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtshadertools
    qt6.qttools
    # gamma 插件找 Qt6::WaylandClient
    qt6.qtwayland
    qt6Packages.qtkeychain
    libcava
    pipewire
    systemd
    # windowpreview：wayland-client + wayland-protocols>=1.41
    wayland
    wayland-protocols
    # files 插件要 gio-unix-2.0
    glib
    # keyboard 插件要 xkbcommon
    libxkbcommon
  ];

  cmakeFlags = [
    # tests/ 需要 niri / matugen / jq / git 等一堆东西，先不构建
    "-DBUILD_TESTING=OFF"
    # 上游默认会找 git 拿当前 commit 写进 clavis_release.h，这里直接给定
    "-DCLAVIS_COMMIT=dff9d03"
    "-DCLAVIS_QML_INSTALL_DIR=${placeholder "out"}/lib/qt6/qml"
    "-DCLAVIS_CONFIG_INSTALL_DIR=${placeholder "out"}/etc/xdg/quickshell/clavis"
    "-DCLAVIS_SYSTEMD_USER_INSTALL_DIR=${placeholder "out"}/lib/systemd/user"
  ];

  # 这个包只产出 QML 插件（没有可执行文件），不需要 qt 的 wrapper；
  # 但 nixpkgs 的 qt6 hook 要求显式声明其中一种。
  dontWrapQtApps = true;

  # Qt 的 QML 插件会把【构建目录】写进 RPATH（因为 libClavisXxxplugin.so 要
  # 链接同目录的 libClavisXxx.so），fixup 阶段会报 “forbidden reference to
  # /build/”。既然这两个 .so 永远同目录，把 /build 条目删掉、补上 $ORIGIN 就行。
  # 注意：那个 /build 检查是在 fixupOutput 里跑的，比 postFixup 【早】，
  # 所以这段必须放 preFixup。
  preFixup = ''
    for f in $(find "$out" -name '*.so'); do
      rpath="$(patchelf --print-rpath "$f" 2>/dev/null || true)"
      new="$(printf '%s' "$rpath" | tr ':' '\n' | grep -v '^/build' | grep -v '^$' | paste -sd: -)"
      case ":$new:" in
        *':$ORIGIN:'*) ;;
        *) if [ -n "$new" ]; then new="$new:\$ORIGIN"; else new='$ORIGIN'; fi ;;
      esac
      patchelf --set-rpath "$new" "$f"
    done
  '';

  meta = {
    description = "Clavis shell（上游 StatIndet/quickshell）";
    homepage = "https://github.com/StatIndet/quickshell";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
