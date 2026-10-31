{
  description = "NixOS flake configuration for host nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Clavis shell 依赖的外部 QML 模块（Material 3 shapes，androidx shape 的 Qt 移植）
    # 上游：https://github.com/soramanew/m3shapes
    m3shapes = {
      url = "github:soramanew/m3shapes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 上游 Quickshell：nixpkgs 只有 0.3.0，Clavis 要求 >= 0.3.1。
    # 0.3.2 自带 overlay，直接当 input 用，避免手写 overrideAttrs。
    # 用固定 commit（= tag v0.3.2）而不是 tag，避免 flake lock 走 GitHub API 触发限流。
    quickshell = {
      url = "github:quickshell-mirror/quickshell/4f508be500dea6e5732cc3d50382a0048b17e7b1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # 上游 Clavis shell 的打包（源码 vendored 在 assets/quickshell/clavis）
    packages.x86_64-linux.clavis-shell =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/clavis-shell.nix { };

    # Clavis 的配套命令行（nixpkgs 没有，见 packages/key-cli.nix）
    packages.x86_64-linux.key-cli =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/key-cli.nix { };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        inputs.home-manager.nixosModules.home-manager
        {
          # 把 pkgs.quickshell 换成上游 0.3.2（home-manager 用 useGlobalPkgs，会跟着走）
          nixpkgs.overlays = [ inputs.quickshell.overlays.default ];
        }
      ];
    };
  };
}
