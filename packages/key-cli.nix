# key-cli（上游 https://github.com/StatIndet/key-cli）的 Nix 打包。
#
# Clavis shell 的配套命令行：shell 生命周期（`key shell`）、系统指标
# （`key sysmon`，C++ 采样器）、剪贴板历史、录屏、键盘状态等。
# 上游只发布 Arch 包，nixpkgs 没有，所以这里自己打。
#
# 产物布局（与 Arch 包保持一致）：
#   $out/bin/key                        Python 入口（setuptools entry point）
#   $out/bin/key-sysmon                 C++ 采样器（Qt6 Core）
#   $out/libexec/key-cli/key-cpu-power  CPU 能耗 helper（可选授权）
#   $out/lib/systemd/user/clavis-clipboard.service
#   $out/lib/udev/rules.d/71-clavis-keyboard-leds.rules
{ lib
, python3Packages
, fetchFromGitHub
, cmake
, ninja
, pkg-config
, qt6
, installShellFiles
}:

python3Packages.buildPythonApplication rec {
  pname = "key-cli";
  version = "2026.9.25";

  src = fetchFromGitHub {
    owner = "StatIndet";
    repo = "key-cli";
    tag = "v${version}";
    hash = "sha256-45pE3W/G0r16d8UfslwDa35H6DB1IEw22JRTE6MoK5A=";
  };

  # 新版 nixpkgs 的 Python 构建器要求显式声明构建系统（不再看 `format`）
  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  # setuptools 主导 Python 部分；native/ 由下面的 postBuild 手动用 CMake 构建。
  # 不设的话 cmake hook 会在 Python 构建前接管 configure。
  dontUseCmakeConfigure = true;
  # key-sysmon 只链 Qt6 Core（无 GUI/插件），不需要 wrapQtAppsHook 的包装
  dontWrapQtApps = true;

  nativeBuildInputs = [ cmake ninja pkg-config installShellFiles ];
  buildInputs = [ qt6.qtbase ];

  propagatedBuildInputs = with python3Packages; [ evdev pyudev ];

  postBuild = ''
    cmake -S native -B native/build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$out \
      -DCMAKE_INSTALL_LIBEXECDIR=libexec \
      -DBUILD_TESTING=OFF
    cmake --build native/build
  '';

  postInstall = ''
    # key-sysmon → $out/bin，key-cpu-power → $out/libexec/key-cli
    cmake --install native/build

    install -Dm644 systemd/user/clavis-clipboard.service \
      $out/lib/systemd/user/clavis-clipboard.service
    install -Dm644 packaging/udev/71-clavis-keyboard-leds.rules \
      $out/lib/udev/rules.d/71-clavis-keyboard-leds.rules
    installShellCompletion --fish completions/key.fish
  '';

  pythonImportsCheck = [ "key_cli" ];

  meta = {
    description = "Clavis command interface, system metrics and desktop backends";
    homepage = "https://github.com/StatIndet/key-cli";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "key";
  };
}
