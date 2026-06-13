# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ inputs, config, pkgs, ... }:

{
  imports = [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [
	"https://cache.nixos.org/"

  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # set fonts
  fonts.fonts = with pkgs; [
    # 基本中文字体（推荐）
    wqy_zenhei # 文泉驿正黑
    wqy_microhei # 文泉驿微米黑
    noto-fonts # Noto 系列（含中文）
    # 可选：更多中文字体
    source-han-sans # 思源黑体
    source-han-serif # 思源宋体
    sarasa-gothic # 更纱黑体
    
    # nerd
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

  # Select internationalisation properties.
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

  # 启用 Fcitx5 输入法框架
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      # fcitx5-rime # 中州韵（Rime）输入引擎
      # fcitx5-mozc # 日文输入引擎
      # fcitx5-hangul # 韩文输入引擎
      # fcitx5-unikey # 越南文输入引擎
      # 您可以根据需要选择安装
    ];
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # enable ssh
  services.openssh = {
    enable=true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
	

  # enable Zsh 
  programs.zsh = {
    enable = true;
    # enable Oh My Zsh
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      # theme powerlevel10k
      theme = "powerlevel10k/powerlevel10k";
    };

    syntaxHighlighting.enable = true;  
    autosuggestions.enable = true;
    enableCompletion = true; 
  
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  # enable docker
  virtualisation.docker.enable = true;  

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tianjiao = {
    isNormalUser = true;
    description = "tianjiao";
    extraGroups = [ "networkmanager" "wheel" ];

    # shell
    shell = pkgs.zsh;

    packages = with pkgs; [
      kdePackages.kate
      # thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "docker-28.5.2" ];

  # Install flatpak
  services.flatpak.enable = true;

  # enable v2raya
  services.v2raya.enable = true;
  boot.kernelModules = [ "tcp_bbr" ];
  # Enable nix-ld for running dynamically linked binaries
  programs.nix-ld.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # basic
    gcc gnumake cmake gdb pkg-config qemu nodejs_22 flex bison elfutils.dev elfutils bc perl python3 openssl nasm
    vim tmux wget git curl unzip unrar
    
    # rust
    cargo
    rustc
   
    # editor
    vscode
    
    # bowsor
    google-chrome firefox
    
    # vpn
    v2raya clash-verge-rev
    
    # fcitx5
    qt6Packages.fcitx5-configtool
    fcitx5-gtk # GTK 程序支持
    
    # terminal
    gnome-terminal

    # zsh
    zsh-powerlevel10k

  ] ++ [
    # cc-switch-cli from flake input
    inputs.cc-switch-cli.packages.x86_64-linux.default
  ];

  # system vari
  environment.variables = {
    # fcitx5 input
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.11"; # Did you read the comment?
}
