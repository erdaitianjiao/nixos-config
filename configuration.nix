# NixOS 系统级配置 —— 桌面 / 服务 / 网络 / 系统软件
# 用户级配置(个人软件 / dotfiles)见 home.nix
{ config, pkgs, ... }:

let
  cc-switch-src = pkgs.fetchurl {
    url = "https://github.com/farion1231/cc-switch/releases/download/v3.20.0/CC-Switch-v3.20.0-Linux-x86_64.AppImage";
    hash = "sha256-+n1jUljSAPPuQ6nyYWc/JXd7VcPEOinUiNF6Dbxlx7Q=";
  };
  cc-switch-contents = pkgs.appimageTools.extractType2 {
    pname = "cc-switch";
    version = "3.20.0";
    src = cc-switch-src;
  };
  cc-switch = pkgs.appimageTools.wrapType2 {
    pname = "cc-switch";
    version = "3.20.0";
    src = cc-switch-src;
    extraInstallCommands = ''
      install -m 444 -D "${cc-switch-contents}/CC Switch.desktop" \
        $out/share/applications/cc-switch.desktop
      install -m 444 -D ${cc-switch-contents}/cc-switch.png \
        $out/share/pixmaps/cc-switch.png
    '';
  };
in {
  # ─── Nix 设置 ───────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 国内镜像加速(否则 cache.nixos.org 拉包很慢)
  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];

  # 自动清理旧代际 / 优化 store(避免磁盘越来越满)
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";
  nix.optimise.automatic = true;

  nixpkgs.config = {
    allowUnfree = true;
  };

  # ─── 启动 (Boot: GRUB on UEFI) ────────────────────────────
  # upstream 分支主动跟随 Nixpkgs 提供的最新主线内核；stable 分支使用默认 LTS。
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = false;   # 关闭原引导器
  boot.loader.grub = {
    enable = true;
    device = "nodev";          # UEFI 模式(BIOS 模式才填 /dev/sda 之类磁盘)
    efiSupport = true;
    useOSProber = true;        # 自动探测其他系统(Windows 等)加入菜单
    gfxmodeEfi = "2560x1440";  # grub 菜单分辨率(屏幕原生 2K)
    gfxpayloadEfi = "keep";    # 内核启动后控制台也保持此分辨率
  };
  boot.kernelModules = [ "tcp_bbr" ];  # 拥塞控制(hardware-configuration.nix 另有 kvm-intel,会自动合并)
  # 内核 IPv4 转发 —— Docker 容器上网必需。默认 0 会导致容器 DNS 解析 / TCP 连接全部失败。
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  # BBR 拥塞控制:加载模块只是第一步,还要切换算法 + 配合 fq 队列才真正生效
  boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
  boot.kernel.sysctl."net.core.default_qdisc" = "fq";

  # ─── 网络 ──────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall = {
    trustedInterfaces = [ "docker0" ];  # 信任 docker 默认网桥, 放行容器出站流量
    allowedTCPPorts = [ 53317 ];  # LocalSend
    allowedUDPPorts = [ 53317 ];
    # 局域网全部放行
    extraCommands = ''
      iptables -I nixos-fw -s 10.0.0.0/8 -j ACCEPT
      iptables -I nixos-fw -s 172.16.0.0/12 -j ACCEPT
      iptables -I nixos-fw -s 192.168.0.0/16 -j ACCEPT
    '';
  };

  # ─── 时间 & 语言 ───────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # ─── 输入法 (Fcitx5) ───────────────────────────────────────
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      (fcitx5-rime.override { rimeDataPkgs = [ rime-ice ]; })
    ];
  };
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # ─── 字体 ──────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    # 中文
    wqy_zenhei
    wqy_microhei
    noto-fonts
    source-han-sans
    source-han-serif
    sarasa-gothic
    # Nerd Fonts
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-cove   # CaskaydiaCove Nerd Font（niri/kitty 配置用）
    nerd-fonts._0xproto         # 0xProto Nerd Font（waybar 用）
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "WenQuanYi Micro Hei Mono" "DejaVu Sans Mono" ];
      sansSerif = [ "WenQuanYi Micro Hei" "DejaVu Sans" ];
      serif = [ "WenQuanYi Zen Hei" "DejaVu Serif" ];
    };
  };

  # ─── 桌面环境 (Plasma 6) ───────────────────────────────────
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ─── niri 会话（Wayland，SDDM 里可选；不影响 Plasma）────────────
  programs.niri.enable = true;
  # 默认仍进 Plasma；登录界面会话菜单里可选 Niri
  services.displayManager.defaultSession = pkgs.lib.mkForce "plasma";

  # ─── 声音 (PipeWire) ───────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ─── 服务 ──────────────────────────────────────────────────
  services.openssh.enable = true;     # SSH
  services.udev.packages = [ pkgs.brightnessctl ];  # 允许普通用户调亮度
  services.printing.enable = true;    # 打印 (CUPS)
  services.flatpak.enable = true;     # Flatpak
  services.v2raya.enable = true;      # 代理

  # ─── 虚拟化 (Docker) ───────────────────────────────────────
  virtualisation.docker.enable = true;
  # docker 28.x 已停维护被 nixpkgs 标为不安全,改用 29.x(docker_29)
  virtualisation.docker.package = pkgs.docker_29;
  # 给容器固定 DNS (国内), 不依赖宿主机 resolv.conf, 避免局域网 DNS 不可达时容器解析失败
  virtualisation.docker.daemon.settings.dns = [ "223.5.5.5" "114.114.114.114" ];

  # ─── NVIDIA 独显 (RTX 4050 Laptop + Intel 核显混合) ────────
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    open = true;                     # Ada 架构 (4050) 推荐 open 内核模块
    nvidiaPersistenced = true;
    powerManagement.enable = true;   # 笔记本空闲时给独显断电, 省电
    prime = {
      offload.enable = true;         # 核显输出画面, N 卡按需启用 (CUDA 可用)
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ─── Shell (Zsh + Oh My Zsh + powerlevel10k) ───────────────
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
    };
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  # ─── 程序 ──────────────────────────────────────────────────
  programs.firefox.enable = true;
  programs.nix-ld.enable = true;  # 运行动态链接的二进制
  programs.steam.enable = true;   # Steam: FHS + 32 位库(home.nix 里的 steam 包已移到这里)

  # ─── 用户 & home-manager ───────────────────────────────────
  users.users.tianjiao = {
    isNormalUser = true;
    description = "tianjiao";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ kdePackages.kate ];
  };

  # home-manager: 用户级配置(个人软件 / dotfiles,只对 tianjiao 生效)
  home-manager = {
    useGlobalPkgs = true;       # 复用系统 nixpkgs,避免重复实例化
    useUserPackages = true;     # 用户包装到用户 profile
    users.tianjiao = import ./home.nix;
  };

  # ─── 系统级软件 ────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # 开发工具
    gcc gnumake cmake gdb pkg-config flex bison bc perl nasm
    elfutils.dev elfutils
    qemu python3 nodejs_22 openssl
    cargo rustc

    # 编辑器 / 浏览器
    vim vscode
    google-chrome
    cc-switch

    # 终端 / 实用工具
    tmux wget git curl unzip unrar
    gnome-terminal
    zsh-powerlevel10k

    # 网络 / 代理
    v2raya
    # AI 编码工具
    opencode
    # 音视频处理
    ffmpeg
    # 文件系统工具
    e2fsprogs
    # clash-verge-rev 改由下方 programs.clash-verge 模块管理（支持服务模式/TUN）

    # 输入法相关
    qt6Packages.fcitx5-configtool
    fcitx5-gtk

    # KDE 全局主题（与当前电脑一致）
    tela-icon-theme
    whitesur-kde

    # niri 桌面 / 状态栏 / 启动器 / 通知 / 工具
    niri kitty waybar fuzzel mako swaybg swaylock
    brightnessctl playerctl wl-clipboard pavucontrol xwayland-satellite
  ];

  # ─── Clash Verge（服务模式，TUN / 系统代理 / DNS 接管必需）────────
  programs.clash-verge = {
    enable = true;
    serviceMode = true; # 用 nix 声明 clash-verge-service systemd 服务，GUI 里直接开 TUN 即可
  };

  # ─── 系统版本(设定后不要改)────────────────────────────────
  system.stateVersion = "25.11";
}
