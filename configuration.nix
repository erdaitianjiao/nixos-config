# NixOS 系统级配置 —— 桌面 / 服务 / 网络 / 系统软件
# 用户级配置(个人软件 / dotfiles)见 home.nix
{ inputs, config, pkgs, ... }:

{
  # ─── Nix 设置 ───────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "docker-28.5.2" ];
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

  # ─── 网络 ──────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

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

  # ─── Shell (Zsh + Oh My Zsh + powerlevel10k) ───────────────
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "powerlevel10k/powerlevel10k";
    };
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  # ─── 程序 ──────────────────────────────────────────────────
  programs.firefox.enable = true;
  programs.nix-ld.enable = true;  # 运行动态链接的二进制

  # ─── 用户 & home-manager ───────────────────────────────────
  users.users.tianjiao = {
    isNormalUser = true;
    description = "tianjiao";
    extraGroups = [ "networkmanager" "wheel" ];
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
    google-chrome firefox

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
