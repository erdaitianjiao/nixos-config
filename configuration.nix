# NixOS 系统级配置 —— 桌面 / 服务 / 网络 / 系统软件
# 用户级配置(个人软件 / dotfiles)见 home.nix
{ inputs, config, pkgs, ... }:

{
  # ─── Nix 设置 ───────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 自动清理旧代际 / 优化 store(避免磁盘越来越满)
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";
  nix.optimise.automatic = true;

  nixpkgs.config = {
    allowUnfree = true;
  };

  # ─── 启动 (Boot: GRUB on UEFI) ────────────────────────────
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
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-chinese-addons ];
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

  # ─── Ollama (本地大模型, N 卡 CUDA 加速) ───────────────────
  services.ollama = {
    enable = true;
    acceleration = "cuda";
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
    extraGroups = [ "networkmanager" "wheel" "docker" ];
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

    # 终端 / 实用工具
    tmux wget git curl unzip unrar
    gnome-terminal
    zsh-powerlevel10k

    # 网络 / 代理
    v2raya clash-verge-rev

    # 输入法相关
    qt6Packages.fcitx5-configtool
    fcitx5-gtk
  ] ++ [
    # 来自 flake input
    inputs.cc-switch-cli.packages.x86_64-linux.default
  ];

  # ─── 系统版本(设定后不要改)────────────────────────────────
  system.stateVersion = "25.11";
}
